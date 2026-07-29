from pathlib import Path

import chromadb
from sentence_transformers import SentenceTransformer

from app.services import job_repository
from app.services.scorer import calculate_ats_score

# ---------------------------------------------------------------------------
# Model ve Kalıcı ChromaDB Başlatma
# ---------------------------------------------------------------------------

# Embedding modeli (import sırasında bir kez yüklenir)
_model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')

# ChromaDB'yi bellekte değil, diskte kalıcı olarak saklıyoruz.
# Böylece her istekte yeniden embedding hesaplamaya gerek kalmaz.
_CHROMA_DIR = Path(__file__).resolve().parents[2] / "data" / "chroma"
_CHROMA_DIR.mkdir(parents=True, exist_ok=True)
_chroma_client = chromadb.PersistentClient(path=str(_CHROMA_DIR))
_collection = _chroma_client.get_or_create_collection(
    name="job_postings",
    metadata={"hnsw:space": "cosine"},
)


# ---------------------------------------------------------------------------
# Veritabanı + Embedding Yenileme (ingest sırasında çağrılır)
# ---------------------------------------------------------------------------

def refresh_embeddings() -> int:
    """SQLite'taki ilanları okur ve ChromaDB'yi günceller.

    Her ilan için embedding'i hesaplayıp kalıcı diske yazar.
    Sadece /api/v1/jobs/ingest endpoint'inden çağrılmalıdır;
    normal /matches isteklerinde ÇAĞRILMAZ.
    """
    jobs = job_repository.all_jobs_for_matching()
    if not jobs:
        print("[*] SQLite'ta ilan yok; embedding oluşturulacak bir şey bulunamadı.")
        return 0

    # Metadata şeması değiştiği için eski koleksiyonu tamamen silip yeniden oluşturuyoruz
    global _collection
    try:
        _chroma_client.delete_collection("job_postings")
    except ValueError:
        pass
    
    _collection = _chroma_client.get_or_create_collection(
        name="job_postings",
        metadata={"hnsw:space": "cosine"},
    )

    ids = [job["id"] for job in jobs]
    documents = [
        f"{job.get('title', '')} {job.get('description', '')} {' '.join(job.get('required_skills', []))}"
        for job in jobs
    ]
    metadatas = [{"title": job["title"], "company": job["company"], "country": job["country"]} for job in jobs]
    embeddings = _model.encode(documents).tolist()

    _collection.add(
        documents=documents,
        embeddings=embeddings,
        metadatas=metadatas,
        ids=ids,
    )
    print(f"[*] {len(ids)} ilan için embedding oluşturuldu ve kalıcı olarak saklandı.")
    return len(ids)


# ---------------------------------------------------------------------------
# İş Eşleştirme (her /matches isteğinde çağrılır — hızlı, API çağrısı yok)
# ---------------------------------------------------------------------------

def calculate_job_match(cv_skills: list, cv_text: str = "", country: str = "ALL", skip: int = 0, limit: int = 20) -> tuple[int, list]:
    """CV yeteneklerini SQLite'taki ilanlarla ChromaDB üzerinden eşleştirir.

    Canlı API çağrısı YAPMAZ. Veriler ingest sırasında doldurulmuş
    SQLite + ChromaDB'den okunur.
    """
    if not cv_skills:
        return []

    # ChromaDB boşsa (hiç ingest yapılmamışsa) kullanıcıya bilgi ver
    total_in_db = _collection.count()
    if total_in_db == 0:
        print("[!] ChromaDB boş — önce /api/v1/jobs/ingest çağrılmalı.")
        return 0, []

    # CV'yi embed et ve ChromaDB'de ara
    combined_text = f"{cv_text} {' '.join(cv_skills)}".strip()
    if not combined_text:
        return 0, []
    cv_embedding = _model.encode([combined_text]).tolist()

    where_filter = {}
    if country and country.upper() != "ALL":
        where_filter = {"country": country.upper()}

    # Toplam sayıyı hesaplamak için (Filtreye göre)
    total_matches = total_in_db
    if where_filter:
        filtered = _collection.get(where=where_filter, include=[])
        total_matches = len(filtered["ids"]) if filtered and filtered["ids"] else 0

    # ChromaDB'de ara (skip + limit kadar getir, slicing ile skip'i atla)
    n_results = min(skip + limit, total_matches)
    if n_results == 0:
        return 0, []

    results = _collection.query(
        query_embeddings=cv_embedding,
        n_results=n_results,
        where=where_filter if where_filter else None,
    )

    # SQLite'tan tam ilan bilgilerini al (location, skills vs.)
    all_jobs = job_repository.all_jobs_for_matching()
    jobs_by_id = {job["id"]: job for job in all_jobs}

    match_results = []
    if results["ids"] and len(results["ids"][0]) > 0:
        # ChromaDB sonuçları zaten uzaklığa (distances) göre küçükten büyüğe sıralıdır.
        # Bu da en yüksek benzerlik (kosinüs) skorundan başlayarak sıralanmış demektir.
        
        # İstediğimiz sayfayı (skip'ten sonrasını) alıyoruz
        page_ids = results["ids"][0][skip:]
        page_metadatas = results["metadatas"][0][skip:]
        page_distances = results["distances"][0][skip:]

        for i in range(len(page_ids)):
            job_id = page_ids[i]
            metadata = page_metadatas[i]
            distance = page_distances[i]

            similarity_score = max(0, int((1 - distance) * 100))

            original_job = jobs_by_id.get(job_id)
            if not original_job:
                continue

            job_skills = original_job.get("required_skills", [])
            ats_details = calculate_ats_score(cv_skills, job_skills, (1 - distance))

            raw_url = original_job.get("link")
            clean_url = raw_url.strip() if raw_url else None

            match_results.append({
                "id": job_id,
                "job_title": metadata["title"],
                "company": metadata["company"],
                "location": original_job.get("location", "Türkiye"),
                "url": clean_url,
                "published_at": original_job.get("published_at", ""),
                "match_score_int": ats_details["ats_score"],
                "match_percentage": f"%{ats_details['ats_score']}",
                "matched_skills": ats_details["matched_skills"],
                "missing_skills": ats_details["missing_skills"],
                "ats_details": ats_details,
            })


    # Sonuçları eşleşme yüzdesine göre en yüksekten en düşüğe sırala (Chroma zaten sıralıdır ama garantiye alalım)
    sorted_matches = sorted(match_results, key=lambda x: x["match_score_int"], reverse=True)
    return total_matches, sorted_matches