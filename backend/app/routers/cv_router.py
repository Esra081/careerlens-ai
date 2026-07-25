from fastapi import APIRouter
from pydantic import BaseModel
from app.services.ai_service import rewrite_cv_bullet, generate_ai_career_coach
import traceback
traceback.print_exc()

router = APIRouter()

# --- Pydantic request modelleri ---

class RewriteRequest(BaseModel):
    old_sentence: str

class CoachRequest(BaseModel):
    target_role: str
    matched_skills: list[str] = []
    missing_skills: list[str]
    ats_score: int


# --- AI Yardımcı Endpoint'leri ---

@router.post("/api/v1/ai/rewrite")
async def api_rewrite_cv(request: RewriteRequest):
    """CV deneyim cümlesini AI ile profesyonelleştirir."""
    new_sentence = rewrite_cv_bullet(request.old_sentence)
    return {
        "old_sentence": request.old_sentence,
        "improved_sentence": new_sentence,
    }

@router.post("/api/v1/ai/coach")
async def api_get_coach(request: CoachRequest):
    """Eksik yeteneklere göre AI kariyer koçluğu verir."""
    advice = generate_ai_career_coach(request.target_role, request.matched_skills, request.missing_skills, request.ats_score)
    return {
        "target_role": request.target_role,
        "coach_advice": advice,
    }