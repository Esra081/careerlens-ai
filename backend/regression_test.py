import os
import shutil
import tempfile
from sentence_transformers import SentenceTransformer
import chromadb

def run_test():
    print("Loading model paraphrase-multilingual-MiniLM-L12-v2...")
    model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')
    
    cv_text = "5 years of experience in Computer Vision and Machine Learning. Developed object detection models using PyTorch, OpenCV, and YOLO. Strong background in Python and Deep Learning."
    cv_skills = ["Python", "PyTorch", "OpenCV", "YOLO", "Machine Learning"]
    
    jobs = [
        {
            "id": "1",
            "title": "Machine Learning Engineer (Computer Vision)",
            "company": "Tech AI",
            "description": "We are looking for an ML Engineer to build state-of-the-art object detection models. Must have experience with Deep Learning frameworks like PyTorch and computer vision libraries like OpenCV.",
            "required_skills": ["Python", "PyTorch", "Computer Vision", "Machine Learning"]
        },
        {
            "id": "2",
            "title": "Satış Mühendisi (Sales Engineer)",
            "company": "Satis A.S.",
            "description": "Müşterilerimize yazılım ürünlerimizin satışını yapacak, ikna kabiliyeti yüksek, B2B satış süreçlerine hakim takım arkadaşı arıyoruz.",
            "required_skills": ["Sales", "B2B", "Communication"]
        },
        {
            "id": "3",
            "title": "İnşaat Proje Yöneticisi",
            "company": "Yapi A.S.",
            "description": "Büyük ölçekli şantiye ve inşaat projelerini yönetecek, AutoCAD ve Primavera kullanabilen, saha mühendisi tecrübeli proje yöneticisi.",
            "required_skills": ["AutoCAD", "Project Management", "Construction"]
        }
    ]

    # CV embedding
    combined_cv_text = f"{cv_text} {' '.join(cv_skills)}".strip()
    cv_embedding = model.encode([combined_cv_text]).tolist()

    print("\n--- Raw Cosine Similarities ---")
    results = []
    for job in jobs:
        doc = f"{job['title']} {job['description']} {' '.join(job['required_skills'])}"
        job_emb = model.encode([doc]).tolist()
        
        # Calculate cosine similarity manually using inner product (SentenceTransformer embeddings are typically normalized, but let's compute exact distance as chromadb does)
        # We will use ChromaDB to be exact as in matcher.py
        results.append((job["id"], doc, job_emb[0]))
        
    temp_dir = tempfile.mkdtemp()
    client = chromadb.PersistentClient(path=temp_dir)
    collection = client.create_collection(name="test", metadata={"hnsw:space": "cosine"})
    
    collection.add(
        ids=[r[0] for r in results],
        documents=[r[1] for r in results],
        embeddings=[r[2] for r in results]
    )
    
    res = collection.query(query_embeddings=cv_embedding, n_results=3)
    
    print("\nResults from ChromaDB:")
    for i in range(3):
        job_id = res['ids'][0][i]
        distance = res['distances'][0][i]
        raw_sim = 1 - distance
        
        # Calibration formula test
        # raw_sim values typically are > 0 for everything, maybe even 0.3 for totally unrelated text.
        
        # We want ML job > 60%, Sales < 30%, Construction < 30%
        # Let's see raw values first
        print(f"Job ID: {job_id}, Distance: {distance:.4f}, Raw Similarity: {raw_sim:.4f}")
        
    shutil.rmtree(temp_dir)

if __name__ == '__main__':
    run_test()
