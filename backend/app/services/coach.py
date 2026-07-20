import os
import google.generativeai as genai
from dotenv import load_dotenv

# Çevresel değişkenleri yükle (.env dosyasından)
load_dotenv()

# API anahtarını yapılandır
api_key = os.getenv("GEMINI_API_KEY")
if api_key:
    genai.configure(api_key=api_key)
    # Hızlı ve etkili analiz için 1.5-flash modelini kullanıyoruz
    model = genai.GenerativeModel('models/gemini-3.5-flash')
else:
    model = None
    print("UYARI: GEMINI_API_KEY bulunamadı!")

def generate_ai_career_coach(target_role: str, missing_skills: list) -> str:
    """Gemini API'sine bağlanıp dinamik mentorluk metni üretir."""
    if not missing_skills:
        return f"Harika! {target_role} rolü için eksik bir yeteneğiniz görünmüyor. Mevcut yeteneklerinizle hemen başvurulara başlayabilirsiniz."
        
    if not model:
        return "AI modeli yapılandırılamadı. Lütfen .env dosyasındaki API anahtarınızı kontrol edin."

    skills_str = ", ".join(missing_skills)
    prompt = f"""
    Sen kıdemli bir Tech Recruiter ve Kariyer Koçusun. 
    Kullanıcının hedeflediği rol: {target_role}.
    Eksik olduğu teknolojiler: {skills_str}.
    
    Bu teknolojileri NEDEN öğrenmesi gerektiğini anlatan, kısa (maksimum 3 cümle), motive edici ve teknik olarak mantıklı bir özet yaz.
    """
    
    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        print(f"🚨 GEMINI HATASI: {str(e)}")
        return "Yapay zeka analiz yaparken bir sorunla karşılaştı, ancak temel yeteneklerini geliştirmeye odaklanmalısın."

def generate_career_advice(job_matches: list) -> dict:
    """Flutter arayüzüne gönderilecek nihai AI tavsiye paketini hazırlar."""
    if not job_matches:
        return {"summary": "Analiz edilecek eşleşme bulunamadı."}

    # En yüksek eşleşmeye sahip ilk ilanı hedef alıyoruz
    top_match = job_matches[0]
    target_role = top_match["job_title"]
    missing_skills = top_match["missing_skills"]

    # 1. Gemini'den dinamik koçluk metnini (summary) al
    ai_summary = generate_ai_career_coach(target_role, missing_skills)

    # 2. Flutter arayüzünün alt alta madde madde (bullet point) basabilmesi için 
    # eksik yetenekleri JSON listesi formatında tutuyoruz.
    learning_path = [{"skill": skill} for skill in missing_skills]

    return {
        "target_role": target_role,
        "summary": ai_summary,
        "learning_path": learning_path
    }