from pathlib import Path

import chromadb
from sentence_transformers import SentenceTransformer

from app.services import job_repository

# ---------------------------------------------------------------------------
# Model ve Kalıcı ChromaDB Başlatma
# ---------------------------------------------------------------------------

# Embedding modeli (import sırasında bir kez yüklenir)
_model = SentenceTransformer('all-MiniLM-L6-v2')

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

    # Mevcut koleksiyonu temizle ve yeniden doldur
    existing = _collection.get()
    if existing["ids"]:
        _collection.delete(ids=existing["ids"])

    ids = [job["id"] for job in jobs]
    documents = [" ".join(job.get("required_skills", ["Bilişim"])) for job in jobs]
    metadatas = [{"title": job["title"], "company": job["company"]} for job in jobs]
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

def calculate_job_match(cv_skills: list) -> list:
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
        return []

    # CV'yi embed et ve ChromaDB'de ara
    cv_text = " ".join(cv_skills)
    cv_embedding = _model.encode([cv_text]).tolist()

    results = _collection.query(
        query_embeddings=cv_embedding,
        n_results=total_in_db,
    )

    # SQLite'tan tam ilan bilgilerini al (location, skills vs.)
    all_jobs = job_repository.all_jobs_for_matching()
    jobs_by_id = {job["id"]: job for job in all_jobs}

    match_results = []
    if results["ids"] and len(results["ids"][0]) > 0:
        for i in range(len(results["ids"][0])):
            job_id = results["ids"][0][i]
            metadata = results["metadatas"][0][i]
            distance = results["distances"][0][i]

            similarity_score = max(0, int((1 - distance) * 100))

            original_job = jobs_by_id.get(job_id)
            if not original_job:
                continue

            job_skills_set = set(s.lower() for s in original_job.get("required_skills", []))
            cv_skills_set = set(s.lower() for s in cv_skills)

            match_results.append({
                "id": job_id,
                "job_title": metadata["title"],
                "company": metadata["company"],
                "location": original_job.get("location", "Türkiye"),
                "match_score_int": similarity_score,
                "match_percentage": f"%{similarity_score}",
                "matched_skills": list(cv_skills_set.intersection(job_skills_set)),
                "missing_skills": list(job_skills_set.difference(cv_skills_set)),
            })

    # Sonuçları eşleşme yüzdesine göre en yüksekten en düşüğe sırala
    sorted_matches = sorted(match_results, key=lambda x: x["match_score_int"], reverse=True)
    return sorted_matches