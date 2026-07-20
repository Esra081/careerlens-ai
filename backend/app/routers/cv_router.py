from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.parser import extract_text_from_pdf
from app.services.extractor import extract_skills
from app.services.scorer import calculate_ats_score
from app.services.matcher import calculate_job_match
from app.services.coach import generate_career_advice
from fastapi import APIRouter
from pydantic import BaseModel
from app.services.ai_service import rewrite_cv_bullet, generate_ai_career_coach

router = APIRouter()

@router.post("/upload-cv")
async def upload_cv(file: UploadFile = File(...)):
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Lütfen sadece PDF formatında bir CV yükleyin.")
    
    try:
        file_bytes = await file.read()
        raw_text = extract_text_from_pdf(file_bytes)
        
        extracted_skills = extract_skills(raw_text)
        ats_evaluation = calculate_ats_score(extracted_skills, raw_text)
        job_matches = calculate_job_match(extracted_skills)
        
        career_coach = generate_ai_career_coach(
            job_matches[0]["job_title"], 
            job_matches[0]["missing_skills"]
        )
        
        return {
            "filename": file.filename,
            "status": "success",
            "parsed_data": {
                "name": "Esra Kılıç",
                "skills": extracted_skills
            },
            "ats_evaluation": ats_evaluation,
            "job_matches": job_matches,
            "career_coach": career_coach # JSON çıktısına eklendi
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dosya işlenirken hata oluştu: {str(e)}")
    
    # Dışarıdan veri almak için Pydantic modelleri
class RewriteRequest(BaseModel):
    old_sentence: str

class CoachRequest(BaseModel):
    target_role: str
    missing_skills: list[str]

@router.post("/api/v1/ai/rewrite")
async def api_rewrite_cv(request: RewriteRequest):
    new_sentence = rewrite_cv_bullet(request.old_sentence)
    return {
        "old_sentence": request.old_sentence,
        "improved_sentence": new_sentence
    }

@router.post("/api/v1/ai/coach")
async def api_get_coach(request: CoachRequest):
    advice = generate_ai_career_coach(request.target_role, request.missing_skills)
    return {
        "target_role": request.target_role,
        "coach_advice": advice
    }