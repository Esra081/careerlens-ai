import os
import google.generativeai as genai
from dotenv import load_dotenv

# .env dosyasındaki ayarları yükle
load_dotenv()

# API anahtarını yapılandır
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("UYARI: GEMINI_API_KEY bulunamadı!")
genai.configure(api_key=api_key)

# Modeli başlat
#model = genai.GenerativeModel('gemini-1.5-flash')
model = genai.GenerativeModel('models/gemini-3.5-flash')

def rewrite_cv_bullet(old_text: str) -> str:
    """Aşama 9: Basit cümleleri etkileyici ATS cümlelerine çevirir."""
    prompt = f"""
    Sen profesyonel bir İK uzmanı ve teknik işe alımcısın (Tech Recruiter).
    Aşağıdaki CV deneyim cümlesini daha profesyonel, sonuç odaklı ve güçlü aksiyon fiilleri (action verbs) içeren bir hale getir. 
    İçinde mutlaka metrik (yüzde, hız artışı vb.) içerebilecek yerleri vurgula veya düzelt.
    Sadece düzeltilmiş yeni cümleyi dön, fazladan açıklama yapma.
    
    Eski Cümle: {old_text}
    """
    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        return f"Yapay zeka hatası: {str(e)}"

def generate_ai_career_coach(target_role: str, missing_skills: list) -> str:
    """Aşama 8: Eksik yeteneklere göre akıllı öğrenme tavsiyesi verir."""
    if not missing_skills:
        return "Harika! Bu rol için eksik bir yeteneğiniz görünmüyor."
        
    skills_str = ", ".join(missing_skills)
    prompt = f"""
    Sen kıdemli bir kariyer koçusun. 
    Kullanıcının hedeflediği rol: {target_role}.
    Eksik olduğu teknolojiler: {skills_str}.
    
    Bu teknolojileri hangi sırayla ve NEDEN öğrenmesi gerektiğini anlatan, kısa, motive edici ve teknik olarak mantıklı bir yol haritası çiz. Maddeleme (bullet points) kullan.
    """
    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        return f"Yapay zeka hatası: {str(e)}"
    