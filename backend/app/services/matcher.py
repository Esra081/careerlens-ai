import chromadb
from sentence_transformers import SentenceTransformer
from app.services.scraper import fetch_real_jobs

def calculate_match_score(cv_skills, job_title):
    # Çok basit bir eşleşme skoru (İleride bunu AI ile güçlendireceğiz)
    score = 0
    for skill in cv_skills:
        if skill.lower() in job_title.lower():
            score += 50
    return min(score, 100) # Maksimum 100

# 1. Modeli ve Veritabanını Başlat
model = SentenceTransformer('all-MiniLM-L6-v2')
chroma_client = chromadb.Client()
collection = chroma_client.get_or_create_collection(
    name="job_postings",
    metadata={"hnsw:space": "cosine"}
)

# 2. Veritabanını Tazeleme Fonksiyonu
def refresh_database():
    print("[*] Veritabanı tazeleniyor...")
    
    # HATA OLAN YERİ DÜZELTTİK: Parametreleri sildik, sadece fonksiyonu çağırıyoruz.
    new_jobs = fetch_real_jobs() 
    
    # Mevcutları sil
    existing_data = collection.get()
    if existing_data['ids']:
        collection.delete(ids=existing_data['ids'])
    
    # Yeni veriyi yükle
    if new_jobs:
        ids = [job["id"] for job in new_jobs]
        
        # job["required_skills"] listesi scraper.py'da tanımlı olmalı, 
        # eğer boşsa hata vermemesi için şu kontrolü ekleyelim:
        documents = [" ".join(job.get("required_skills", ["Bilişim"])) for job in new_jobs]
        
        metadatas = [{"title": job["title"], "company": job["company"]} for job in new_jobs]
        embeddings = model.encode(documents).tolist()
        
        collection.add(
            documents=documents,
            embeddings=embeddings,
            metadatas=metadatas,
            ids=ids
        )
    return new_jobs

# Dosyanın en altını şöyle yap:
try:
    CURRENT_JOBS = refresh_database()
    print("[*] Veritabanı başarıyla tazelendi ve ilanlar yüklendi.")
except Exception as e:
    print(f"[!] HATA: Veritabanı tazelenirken bir hata oluştu: {e}")
    CURRENT_JOBS = [] # Hata olsa bile uygulama çökmesin

# 3. SENİN ARIYORDUN HATA OLAN KISIM BURASI (Eklendi)
def calculate_job_match(cv_skills: list) -> list:
    print(f"[*] Analiz edilecek CV becerileri: {cv_skills}")
    print(f"[*] Veritabanındaki toplam ilan sayısı: {len(CURRENT_JOBS)}")

    if not cv_skills or not CURRENT_JOBS:
        return []
        
    cv_text = " ".join(cv_skills)
    cv_embedding = model.encode([cv_text]).tolist()
    
    results = collection.query(
        query_embeddings=cv_embedding,
        n_results=3
    )
    
    match_results = []
    if results['ids'] and len(results['ids'][0]) > 0:
        for i in range(len(results['ids'][0])):
            job_id = results['ids'][0][i]
            metadata = results['metadatas'][0][i]
            distance = results['distances'][0][i] 
            
            similarity_score = max(0, int((1 - distance) * 100))
            
            # Güncel iş listesinden eşleşen ilanı bul
            original_job = next(job for job in CURRENT_JOBS if job["id"] == job_id)
            job_skills_set = set([s.lower() for s in original_job["required_skills"]])
            cv_skills_set = set([s.lower() for s in cv_skills])
            
            match_results.append({
                "job_title": metadata["title"],
                "company": metadata["company"],
                "match_percentage": f"%{similarity_score}",
                "matched_skills": list(cv_skills_set.intersection(job_skills_set)),
                "missing_skills": list(job_skills_set.difference(cv_skills_set))
            })
    return match_results