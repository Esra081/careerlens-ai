from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from app.services.parser import extract_text_from_pdf
from app.services.extractor import extract_skills
from app.services.scorer import calculate_ats_score
from app.services.matcher import calculate_job_match
from app.services.coach import generate_career_advice
from app.services.cv_manager import get_saved_cv
from app.services.scraper import fetch_real_jobs
from app.services.cv_manager import save_cv

CURRENT_JOBS = []
app = FastAPI(title="CareerLens AI", description="CV Analysis & Career Coaching API", version="1.0.0")

@app.post("/upload-cv")
def upload_cv(cv_data: dict):
    """Kullanıcı mobil uygulamadan CV gönderdiğinde tetiklenir."""
    # 1. CV'yi dosyaya (user_cv.json) kaydeder
    save_cv(cv_data)
    
    # 2. İstersen kaydettikten sonra otomatik bir tarama başlatabilirsin:
    # from app.services.scraper import fetch_real_jobs
    # fetch_real_jobs() 
    
    return {"message": "CV kaydedildi, artık otomatik taranacak."}

@app.get("/api/v1/jobs")
def get_all_jobs():
    global CURRENT_JOBS  # <--- global bildirimini en başa al!
    
    saved_cv = get_saved_cv()
    
    if not saved_cv:
        return {"total": 0, "jobs": [], "message": "Lütfen önce CV'nizi yükleyin."}
    
    # Şimdi CURRENT_JOBS burada global olarak tanınıyor
    if not CURRENT_JOBS:
        print("[*] İlanlar boş, güncelleniyor...")
        CURRENT_JOBS = fetch_real_jobs() # global değişkene ata
    
    return {"total": len(CURRENT_JOBS), "jobs": CURRENT_JOBS}

# Flutter (Mobil/Web) üzerinden gelecek isteklere izin vermek için CORS ayarı
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/v1/analyze-cv")
async def analyze_cv_endpoint(file: UploadFile = File(...)):
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Sadece PDF formatı desteklenmektedir.")
    
    try:
        # 1. Dosyayı oku
        file_bytes = await file.read()
        
        # 2. Metni çıkar (parser.py)
        raw_text = extract_text_from_pdf(file_bytes)
        
        # 3. Yetenekleri çıkar (extractor.py)
        extracted_skills = extract_skills(raw_text)
        
        # 4. ATS Skoru Hesapla (scorer.py)
        ats_result = calculate_ats_score(extracted_skills, raw_text)
        
        # 5. İş Eşleştirmesi Yap (matcher.py)
        job_matches = calculate_job_match(extracted_skills)
        
        # 6. AI Kariyer Tavsiyesi Al (coach.py)
        # Sadece en iyi eşleşen ilan için tavsiye üretiyoruz
        career_advice = generate_career_advice(job_matches)
        
        # Sonuçları JSON olarak dön
        return {
            "status": "success",
            "data": {
                "parsed_skills": extracted_skills,
                "ats_score": ats_result,
                "job_matches": job_matches[:3], # Sadece en iyi 3 eşleşme
                "career_advice": career_advice
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"CV Analiz Hatası: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)