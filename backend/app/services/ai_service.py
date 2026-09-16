import os
try:
    from google import genai
except ImportError:
    genai = None
from dotenv import load_dotenv

# .env dosyasındaki ayarları yükle
load_dotenv()

# --- TEK NOKTADAN GEMİNİ YAPILANDIRMASI ---
# Tüm AI fonksiyonları bu dosyadaki model örneğini kullanır.
_api_key = os.getenv("GEMINI_API_KEY")
_client = None
if _api_key and genai:
    try:
        _client = genai.Client(api_key=_api_key)
    except Exception as e:
        print(f"UYARI: Gemini client başlatılamadı: {e}")
elif not _api_key:
    print("UYARI: GEMINI_API_KEY bulunamadı! AI özellikleri devre dışı.")
elif not genai:
    print("UYARI: google-genai paketi bulunamadı! AI özellikleri devre dışı.")


def _require_client():
    """Client yapılandırılmamışsa açık hata verir."""
    if genai is None:
        raise RuntimeError(
            "google-genai kütüphanesi yüklenemedi. Lütfen sanal ortamın (backend/venv) aktif olduğundan emin olun."
        )
    if _client is None:
        raise RuntimeError(
            "AI modeli yapılandırılamadı. Lütfen .env dosyasındaki GEMINI_API_KEY değerini kontrol edin."
        )
    return _client


import json

import re

def extract_skills_via_ai(text: str) -> dict:
    """Gemini modelini kullanarak metinden yetenekleri ve deneyim seviyesini yapılandırılmış JSON olarak çıkarır."""
    client = _require_client()
    prompt = f"""
Sen uzman bir teknik İK analistisin.
Aşağıdaki CV metnini incele ve şu iki bilgiyi çıkar:
1. Tüm teknik beceriler (yazılım dilleri, frameworkler, araçlar, kütüphaneler, veritabanları, bulut teknolojileri vb.)
2. Adayın Deneyim Seviyesi (Sadece şu 3 değerden biri olmalı: "Junior", "Mid", veya "Senior")

YALNIZCA geçerli bir JSON nesnesi döndür, başka hiçbir metin, açıklama veya markdown etiketleri İÇERMEMELİDİR.
Örnek Çıktı: {{"skills": ["Python", "React", "Docker"], "experience_level": "Mid"}}

Metin:
{text}
"""
    import time
    max_retries = 2
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(model='gemini-2.5-flash', contents=prompt)
            content = response.text.strip()

            # Regex ile en dıştaki JSON bloğunu bul
            json_match = re.search(r'\{[\s\S]*\}', content)
            if json_match:
                json_str = json_match.group(0)
            else:
                json_str = content

            result = json.loads(json_str)
            if isinstance(result, dict):
                # Olası anahtar adlarını esnekçe tara
                skills = []
                for k in ["skills", "Skills", "technical_skills", "technologies", "tech_stack"]:
                    if k in result and isinstance(result[k], list):
                        skills = [str(s).strip() for s in result[k] if str(s).strip()]
                        break

                exp_level = "Junior"
                for k in ["experience_level", "Experience_Level", "experience", "level"]:
                    if k in result and str(result[k]).strip():
                        val = str(result[k]).strip().capitalize()
                        if val in ["Junior", "Mid", "Senior"]:
                            exp_level = val
                        break

                if skills:
                    return {"skills": skills, "experience_level": exp_level}

            return {"skills": [], "experience_level": "Junior"}
        except Exception as e:
            error_msg = str(e)
            if "429" in error_msg or "ResourceExhausted" in error_msg or "Quota" in error_msg:
                if attempt < max_retries - 1:
                    print(f"⚠️ GEMINI 429 KOTASI AŞILDI (Deneme {attempt+1}). 15 saniye bekleniyor...")
                    time.sleep(15)
                    continue
            print(f"🚨 GEMINI JSON HATASI (Beceri Çıkarımı): {error_msg}")
            raise e # Hata fırlat ki fallback devreye girsin



def rewrite_cv_bullet(old_text: str, lang: str = "tr") -> str:
    """Basit cümleleri etkileyici ATS cümlelerine çevirir."""
    client = _require_client()
    prompt = f"""
CRITICAL SYSTEM RULE: You MUST translate ALL of your analysis and text strictly into the language of '{lang}'. IF YOU USE ANY OTHER LANGUAGE, THE SYSTEM WILL CRASH.

Sen profesyonel bir İK uzmanı ve teknik işe alımcısın (Tech Recruiter).
Aşağıdaki CV deneyim cümlesini daha profesyonel, sonuç odaklı ve güçlü aksiyon fiilleri (action verbs) içeren bir hale getir. 
İçinde mutlaka metrik (yüzde, hız artışı vb.) içerebilecek yerleri vurgula veya düzelt.
Sadece düzeltilmiş yeni cümleyi dön, fazladan açıklama yapma.

Eski Cümle: {old_text}

CRITICAL SYSTEM RULE: You MUST translate ALL of your analysis and text strictly into the language of '{lang}'. IF YOU USE ANY OTHER LANGUAGE, THE SYSTEM WILL CRASH.
    """
    try:
        response = client.models.generate_content(model='gemini-2.5-flash', contents=prompt)
        return response.text.strip()
    except Exception as e:
        return f"Yapay zeka hatası: {str(e)}"


def generate_ai_career_coach(target_role: str, matched_skills: list, missing_skills: list, ats_score: int = 0, lang: str = "tr", skills: list = None, experience_level: str = "Junior") -> str:
    """Gemini API'sine bağlanıp acımasız ve gerçekçi dinamik mentorluk metni üretir."""
    client = _require_client()
    
    matched_str = ", ".join(matched_skills) if matched_skills else "Belirtilmemiş"
    missing_str = ", ".join(missing_skills) if missing_skills else "Belirtilmemiş"
    all_skills_str = ", ".join(skills) if skills else "Belirtilmemiş"

    target_lang = "tr" if (not lang or lang.lower().startswith("tr")) else lang.lower()
    
    prompt = f"""
CRITICAL SYSTEM RULE: You MUST write ALL of your analysis and text strictly and entirely in '{target_lang}' language. IF YOU USE ANY OTHER LANGUAGE, THE SYSTEM WILL CRASH.

Sen acımasız, aşırı gerçekçi ve son derece titiz bir Senior Tech Recruiter ve Engineering Manager'sın.
ASLA "Harika bir CV", "Çok iyisin", "Mükemmel" gibi sahte övgüler yapma. Adayın eksiklerini net, profesyonel, sert ve yapıcı bir dille belirt.
Karşındaki kişi "{target_role}" ilanı için BAŞVURAN bir aday.
Adayın Deneyim Seviyesi: {experience_level}
Adayın Anlamsal Uyum (ATS) Skoru: %{ats_score}/100
Adayın Bildiği Tüm Yetenekler: {all_skills_str}
Adayın Sahip Olduğu Yetenekler (İlanla Eşleşen): {matched_str}
Adayın Eksik Olduğu (İlanda İstenen) Yetenekler: {missing_str}

Gelen iş ilanı metni hangi dilde olursa olsun, özetlemeyi KESİNLİKLE talep edilen dilde ({target_lang}) yap.

Yanıtın KESİNLİKLE aşağıdaki 3 başlığı (tam olarak bu format ve emojilerle) içermelidir:

### 1. 📊 Gerçekçi Uyum Analizi
CV ile ilan arasındaki uyum ve eksiklikler nerede? Aday neden doğrudan elenebilir? (Açık ve net bir dille açıkla).

### 2. 🎯 Kapatılması Gereken Açık & Proje Önerisi
Eksik olan beceriler işin aslında ne işe yarıyor? Aday bu yetenekleri kanıtlamak için yarın sabah HANGİ SPESİFİK PROJEYE başlamalı? (Doğrudan somut teknik mimari veya proje adı ver).

### 3. ✍️ CV İyileştirme (STAR Formatı)
Adayın sahip olduğu yeteneklerden birini seç. Sıradan bir cümleyi STAR (Situation, Task, Action, Result) tekniğiyle yazılmış, sayısal metrikler içeren profesyonel bir CV maddesine dönüştür.
Format:
- **Eski Hali:** [Sıradan bir CV cümlesi]
- **Olması Gereken Hali:** [STAR formatında, metrik içeren güçlü cümle]

CRITICAL SYSTEM RULE: You MUST write ALL of your analysis and text strictly and entirely in '{target_lang}' language.
"""
    try:
        response = client.models.generate_content(model='gemini-2.5-flash', contents=prompt)
        return response.text.strip()
    except Exception as e:
        print(f"🚨 GEMINI HATASI (AI Koç): {str(e)}")
        return "Yapay zeka analizi şu an kullanılamıyor. Lütfen eksik becerilerinizi tamamlamaya odaklanın."


def generate_career_advice(
    job_matches: list,
    lang: str = "tr",
    skills: list = None,
    experience_level: str = "Junior"
) -> dict:
    """Flutter arayüzüne gönderilecek nihai AI tavsiye paketini hazırlar."""
    if not job_matches:
        return {"summary": "Analiz edilecek eşleşme bulunamadı.", "learning_path": []}

    # En yüksek eşleşmeye sahip ilk ilanı hedef alıyoruz
    top_match = job_matches[0]
    target_role = top_match.get("job_title", "Software Developer")
    matched_skills = top_match.get("matched_skills", [])
    missing_skills = top_match.get("missing_skills", [])
    ats_score = top_match.get("match_score_int", 0)

    # Gemini'den dinamik koçluk metnini (summary) al
    ai_summary = generate_ai_career_coach(
        target_role=target_role,
        matched_skills=matched_skills,
        missing_skills=missing_skills,
        ats_score=ats_score,
        lang=lang,
        skills=skills,
        experience_level=experience_level,
    )

    # Flutter arayüzünün alt alta madde madde basabilmesi için
    # eksik yetenekleri JSON listesi formatında tutuyoruz.
    learning_path = [{"skill": skill} for skill in missing_skills]

    return {
        "target_role": target_role,
        "summary": ai_summary,
        "learning_path": learning_path,
    }