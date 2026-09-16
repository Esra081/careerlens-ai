import sys
import os
import subprocess
from pathlib import Path

# 1. Backend ve sanal ortam (venv) yollarını tespit et
backend_dir = Path(__file__).resolve().parent.parent
venv_python = backend_dir / "venv" / "Scripts" / "python.exe"

# 2. Eğer dosya VS Code veya terminalde sistem Python'ı ile çalıştırıldıysa,
# doğrudan projenin tüm paketlerinin kurulu olduğu 'backend/venv' ortamına devret!
if venv_python.exists():
    current_exe = Path(sys.executable).resolve()
    target_exe = venv_python.resolve()
    if current_exe != target_exe:
        print(f"[CareerLens AI] Sanal ortam otomatik aktive ediliyor: {target_exe}")
        try:
            result = subprocess.run([str(target_exe)] + sys.argv)
            sys.exit(result.returncode)
        except KeyboardInterrupt:
            sys.exit(0)

# 3. Backend dizinini sys.path'e otomatik ekle (app paketinin her zaman bulunabilmesi için)
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import json
import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from app.services.parser import extract_text_from_pdf
from app.services.extractor import extract_skills
from app.services.matcher import calculate_job_match, refresh_embeddings
from app.services.ai_service import generate_career_advice
from app.services.job_api import fetch_real_jobs
from app.services import job_repository
from app.services.notification_service import init_firebase, send_job_match_notification
from app.routers.cv_router import router as cv_router
from app.routers.auth_router import router as auth_router
from pydantic import BaseModel

app = FastAPI(title="CareerLens AI", version="0.3.0")

# Flutter (Mobil/Web) üzerinden gelecek isteklere izin vermek için CORS ayarı
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router'ları bağla
app.include_router(auth_router)
app.include_router(cv_router)


PROFILE_FILE = "user_profile.json"

# ---------------------------------------------------------------------------
# Arka Plan Görevleri (Scheduler)
# ---------------------------------------------------------------------------

scheduler = AsyncIOScheduler()

def run_ingestion_task():
    """Arka planda harici API'lerden ilanları çeker, SQLite'a kaydeder ve ChromaDB'yi günceller."""
    print("[Scheduler] Arka plan ilan çekme ve embedding işlemi başlatılıyor...")
    try:
        jobs = fetch_real_jobs()
        upserted = job_repository.upsert_jobs(jobs)
        embedded = refresh_embeddings()
        print(f"[Scheduler] İşlem tamamlandı. Çekilen: {len(jobs)}, SQLite: {upserted}, ChromaDB: {embedded}")
        
        # --- OTOMATİK BİLDİRİM MANTIĞI ---
        # TODO: Multi-user yapısına geçildiğinde DB'den yetenekler çekilerek çalıştırılacak
        """
        token_path = "fcm_token.txt"
        if os.path.exists(token_path) and os.path.exists(PROFILE_FILE):
            with open(token_path, "r") as f:
                token = f.read().strip()
                
            if token:
                with open(PROFILE_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    user_skills = data.get("skills", [])
                    
                if user_skills:
                    raw_text = " ".join(user_skills)
                    _, all_matches = calculate_job_match(user_skills, raw_text, "ALL", 0, 5)
                    if all_matches and len(all_matches) > 0:
                        top_match = all_matches[0]
                        score = top_match.get("match_score_int", 0)
                        if score >= 75:
                            print(f"[Scheduler] Yüksek eşleşme bulundu! Bildirim atılıyor... %{score}")
                            send_job_match_notification(token, top_match["job_title"], top_match["company"], score)
        """
                            
    except Exception as e:
        print(f"[Scheduler] Arka plan görevinde hata oluştu: {e}")

@app.on_event("startup")
async def startup_event():
    print("[App] API ayağa kalkıyor, arka plan görevleri başlatılıyor...")
    
    # Firebase'i başlat
    init_firebase()
    
    # Görevi her 6 saatte bir çalışacak şekilde planla
    scheduler.add_job(run_ingestion_task, "interval", hours=6)
    scheduler.start()
    
    # İlk veritabanı dolumu için API boot sürecini bloklamadan görevi asenkron tetikle
    asyncio.create_task(asyncio.to_thread(run_ingestion_task))


# ---------------------------------------------------------------------------
# API Endpoint'leri
# ---------------------------------------------------------------------------

class FcmTokenRequest(BaseModel):
    token: str

@app.post("/api/v1/fcm-token")
def save_fcm_token(req: FcmTokenRequest):
    """Gelen FCM Token'ı dosyaya kaydeder."""
    try:
        with open("fcm_token.txt", "w") as f:
            f.write(req.token)
        return {"status": "success", "message": "Token kaydedildi."}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Token kaydedilemedi.")

class TestNotificationRequest(BaseModel):
    token: str
    job_title: str
    company: str
    score: int

@app.post("/api/v1/test-notification")
def test_notification(req: TestNotificationRequest):
    """FCM Token kullanarak cihaza test bildirimi yollar."""
    success = send_job_match_notification(req.token, req.job_title, req.company, req.score)
    if success:
        return {"status": "success", "message": "Bildirim başarıyla gönderildi."}
    else:
        raise HTTPException(status_code=500, detail="Bildirim gönderilemedi.")

@app.post("/api/v1/upload-cv")
async def upload_cv(file: UploadFile = File(...)):
    """CV yükler, PDF'den yetenekleri çıkarır ve profili kaydeder."""
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Sadece PDF formatı desteklenmektedir.")

    try:
        file_bytes = await file.read()
        raw_text = extract_text_from_pdf(file_bytes)
        extracted_data = extract_skills(raw_text)
        extracted_skills = extracted_data.get("skills") or []
        experience_level = extracted_data.get("experience_level") or "Junior"

        return {"message": "CV başarıyla kaydedildi.", "skills": extracted_skills, "experience_level": experience_level}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"CV Yükleme Hatası: {str(e)}")



class MatchRequest(BaseModel):
    skills: list[str] = []
    experience_level: str = "Junior"
    country: str = "ALL"
    skip: int = 0
    limit: int = 20
    experience: str | None = None
    work_model: str | None = None
    min_salary: int | None = None
    lang: str = "tr"

@app.post("/api/v1/matches")
async def get_matches(request: MatchRequest):
    """Kullanıcının yeteneklerine göre iş ilanı eşleşmelerini döndürür."""
    user_skills = [skill.strip() for skill in request.skills if skill.strip()]
    raw_text = " ".join(user_skills) if user_skills else ""

    total_matches, all_matches = calculate_job_match(
        cv_skills=user_skills,
        cv_text=raw_text,
        country=request.country,
        skip=request.skip,
        limit=request.limit,
        experience=request.experience,
        work_model=request.work_model,
        min_salary=request.min_salary
    )
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


def _run_ingestion():
    """Arka planda çalışan asıl ilan çekme fonksiyonu."""
    print("[Ingest] Arka plan işlemi başladı.")
    try:
        jobs = fetch_real_jobs()
        upserted = job_repository.upsert_jobs(jobs)
        embedded = refresh_embeddings()
        print(f"[Ingest] Başarılı: {len(jobs)} çekildi, {upserted} yazıldı, {embedded} embed edildi.")
    except Exception as e:
        print(f"[Ingest] Hata oluştu: {str(e)}")

@app.post("/api/v1/jobs/ingest")
def ingest_jobs(background_tasks: BackgroundTasks):
    """Harici API'lerden ilanları çeker, SQLite'a yazar ve embedding'leri günceller.
    İşlemi arka plana delege edip hemen yanıt döner.
    """
    background_tasks.add_task(_run_ingestion)
    
    return {
        "status": "success",
        "message": "İlan güncelleme arka planda başlatıldı."
    }


@app.post("/api/v1/analyze-cv")
async def analyze_cv_endpoint(file: UploadFile = File(...), country: str = "ALL", lang: str = "tr"):
    """Tam CV analiz pipeline'ı: PDF → yetenek çıkarma → ATS skoru → eşleştirme → AI koçluk."""
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Sadece PDF formatı desteklenmektedir.")

    try:
        # 1. Dosyayı oku
        file_bytes = await file.read()

        # 2. Metni çıkar (parser.py)
        raw_text = extract_text_from_pdf(file_bytes)

        # 3. Yetenekleri çıkar (extractor.py)
        extracted_data = extract_skills(raw_text)
        extracted_skills = extracted_data.get("skills") or []
        experience_level = extracted_data.get("experience_level") or "Junior"

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
        career_advice = generate_career_advice(
            job_matches,
            lang=lang,
            skills=extracted_skills,
            experience_level=experience_level,
        )

        # Sonuçları JSON olarak dön
        return {
            "status": "success",
            "data": {
                "parsed_skills": extracted_skills,
                "experience_level": experience_level,
                "ats_score": ats_result,
                "job_matches": job_matches,
                "career_advice": career_advice,
            },
        }
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"CV Analiz Hatası: {str(e)}")



if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True, app_dir=str(backend_dir))

