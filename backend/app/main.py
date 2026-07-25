from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import json
import os

from app.services.parser import extract_text_from_pdf
from app.services.extractor import extract_skills
from app.services.matcher import calculate_job_match, refresh_embeddings
from app.services.ai_service import generate_career_advice
from app.services.job_api import fetch_real_jobs
from app.services import job_repository
from app.routers.cv_router import router as cv_router

app = FastAPI(title="CareerLens AI", version="0.2.0")

# Flutter (Mobil/Web) üzerinden gelecek isteklere izin vermek için CORS ayarı
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# AI yardımcı endpoint'lerini bağla (/api/v1/ai/rewrite, /api/v1/ai/coach)
app.include_router(cv_router)

PROFILE_FILE = "user_profile.json"


# ---------------------------------------------------------------------------
# API Endpoint'leri
# ---------------------------------------------------------------------------

@app.post("/api/v1/upload-cv")
async def upload_cv(file: UploadFile = File(...)):
    """CV yükler, PDF'den yetenekleri çıkarır ve profili kaydeder."""
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Sadece PDF formatı desteklenmektedir.")

    try:
        file_bytes = await file.read()
        raw_text = extract_text_from_pdf(file_bytes)
        extracted_skills = extract_skills(raw_text)

        # Çıkarılan yetenekleri ve ham metni yerel bir dosyaya kaydet
        with open(PROFILE_FILE, "w", encoding="utf-8") as f:
            json.dump({"skills": extracted_skills, "raw_text": raw_text}, f)

        return {"message": "CV başarıyla kaydedildi.", "skills": extracted_skills}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"CV Yükleme Hatası: {str(e)}")


@app.get("/api/v1/matches")
async def get_matches(skills: str | None = None, country: str = "ALL", skip: int = 0, limit: int = 20):
    """Kullanıcının yeteneklerine göre iş ilanı eşleşmelerini döndürür."""
    # Kayıtlı CV yeteneklerini oku
    if skills:
        user_skills = [skill.strip() for skill in skills.split(",") if skill.strip()]
        with open(PROFILE_FILE, "w", encoding="utf-8") as profile_file:
            json.dump({"skills": user_skills}, profile_file)
    elif not os.path.exists(PROFILE_FILE):
        return {"error": "Önce CV yüklemelisiniz."}
    else:
        with open(PROFILE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            user_skills = data.get("skills", [])
            raw_text = data.get("raw_text", "")

    raw_text = " ".join(user_skills)

    total_matches, all_matches = calculate_job_match(user_skills, raw_text, country, skip, limit)
    response = {
        "total": total_matches,
        "matches": all_matches,
    }
    return JSONResponse(
        content=response,
        headers={"Cache-Control": "no-store, no-cache, max-age=0, must-revalidate"},
    )


@app.get("/api/v1/jobs")
def get_all_jobs(skip: int = 0, limit: int = 50):
    """SQLite'tan sayfalanmış iş ilanlarını döndürür."""
    page = (skip // limit) + 1 if limit > 0 else 1
    total, jobs = job_repository.list_jobs(page=page, page_size=limit)
    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "last_refresh": job_repository.last_refresh_at(),
        "jobs": jobs,
    }


@app.post("/api/v1/jobs/ingest")
def ingest_jobs():
    """Harici API'lerden ilanları çeker, SQLite'a yazar ve embedding'leri günceller.

    Bu endpoint ağır bir işlemdir (~15 HTTP çağrısı + embedding hesaplama).
    Normalde günde 1-2 kez veya ihtiyaç duyulduğunda çağrılır;
    kullanıcı istekleri sırasında DEĞİL.
    """
    # 1. Harici API'lerden ilanları çek
    jobs = fetch_real_jobs()

    # 2. SQLite'a kaydet (upsert)
    upserted = job_repository.upsert_jobs(jobs)

    # 3. ChromaDB embedding'lerini yenile
    embedded = refresh_embeddings()

    return {
        "status": "success",
        "fetched_from_apis": len(jobs),
        "upserted_to_db": upserted,
        "embeddings_refreshed": embedded,
        "total_in_db": job_repository.job_count(),
    }


@app.post("/api/v1/analyze-cv")
async def analyze_cv_endpoint(file: UploadFile = File(...), country: str = "ALL"):
    """Tam CV analiz pipeline'ı: PDF → yetenek çıkarma → ATS skoru → eşleştirme → AI koçluk."""
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Sadece PDF formatı desteklenmektedir.")

    try:
        # 1. Dosyayı oku
        file_bytes = await file.read()

        # 2. Metni çıkar (parser.py)
        raw_text = extract_text_from_pdf(file_bytes)

        # 3. Yetenekleri çıkar (extractor.py)
        extracted_skills = extract_skills(raw_text)

        # /matches endpoint'i aynı CV yeteneklerini kullanarak daha sonra
        # güncel ilanları eşleştirebilsin diye profili kaydet.
        with open(PROFILE_FILE, "w", encoding="utf-8") as profile_file:
            json.dump({"skills": extracted_skills, "raw_text": raw_text}, profile_file)

        # 4. İş Eşleştirmesi Yap (matcher.py)
        # Sadece en iyi 3 eşleşme için limit veriyoruz
        _, job_matches = calculate_job_match(extracted_skills, raw_text, country, limit=3)

        # 5. ATS Skoru Al (En iyi eşleşen ilan üzerinden)
        if job_matches:
            ats_result = job_matches[0]["ats_details"]
        else:
            ats_result = {"ats_score": 0, "matched_skills": [], "missing_skills": [], "details": {}}

        # 6. AI Kariyer Tavsiyesi Al (ai_service.py)
        # Sadece en iyi eşleşen ilan için tavsiye üretiyoruz
        career_advice = generate_career_advice(job_matches)

        # Sonuçları JSON olarak dön
        return {
            "status": "success",
            "data": {
                "parsed_skills": extracted_skills,
                "ats_score": ats_result,
                "job_matches": job_matches,
                "career_advice": career_advice,
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"CV Analiz Hatası: {str(e)}")


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
