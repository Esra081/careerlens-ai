# Bu modül artık ai_service.py'ye taşındı.
# Mevcut import'ları bozmamak için yeniden dışa aktarım (re-export) yapılır.
from app.services.ai_service import generate_ai_career_coach, generate_career_advice

__all__ = ["generate_ai_career_coach", "generate_career_advice"]