import os
from google import genai
from dotenv import load_dotenv

# .env dosyasındaki ayarları yükle
load_dotenv()

# --- TEK NOKTADAN GEMİNİ YAPILANDIRMASI ---
# Tüm AI fonksiyonları bu dosyadaki model örneğini kullanır.
_api_key = os.getenv("GEMINI_API_KEY")
_client = None
if _api_key:
    _client = genai.Client(api_key=_api_key)
else:
    print("UYARI: GEMINI_API_KEY bulunamadı! AI özellikleri devre dışı.")


def _require_client():
    """Client yapılandırılmamışsa açık hata verir."""
    if _client is None:
        raise RuntimeError(
            "AI modeli yapılandırılamadı. Lütfen .env dosyasındaki GEMINI_API_KEY değerini kontrol edin."
        )
    return _client


import json

def extract_skills_via_ai(text: str) -> list:
    """Gemini modelini kullanarak metinden yetenekleri (teknik beceriler) yapılandırılmış JSON olarak çıkarır."""
    client = _require_client()
    prompt = f"""
Sen uzman bir teknik İK analistisin.
Aşağıdaki CV metninde yer alan tüm teknik becerileri (yazılım dilleri, frameworkler, araçlar, veritabanları, teknolojiler) çıkar.
YALNIZCA geçerli bir JSON listesi döndür, başka hiçbir metin, açıklama veya markdown (```json ... ```) etiketleri İÇERMEMELİDİR.
Eğer hiç beceri bulamazsan boş bir liste [] döndür.
Örnek Çıktı: ["Python", "React", "Docker"]

Metin:
{text}
"""
    import time
    max_retries = 2
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(model='gemini-2.5-flash', contents=prompt)
            content = response.text.strip()
            
            # Olası markdown kalıntılarını temizle
            if content.startswith("```json"):
                content = content[7:]
            if content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]
            content = content.strip()
            
            skills = json.loads(content)
            if isinstance(skills, list):
                return skills
            return []
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
    Sen profesyonel bir İK uzmanı ve teknik işe alımcısın (Tech Recruiter).
    Aşağıdaki CV deneyim cümlesini daha profesyonel, sonuç odaklı ve güçlü aksiyon fiilleri (action verbs) içeren bir hale getir. 
    İçinde mutlaka metrik (yüzde, hız artışı vb.) içerebilecek yerleri vurgula veya düzelt.
    Sadece düzeltilmiş yeni cümleyi dön, fazladan açıklama yapma.
    
    Eski Cümle: {old_text}
    
    CRITICAL RULE: You MUST generate your entire response strictly in the following language code: '{lang}' (e.g., 'tr' for Turkish, 'de' for German, 'en' for English). Do not use any other language.
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

    prompt = f"""
Sen acımasız, aşırı gerçekçi ve son derece titiz bir Senior Tech Recruiter ve Engineering Manager'sın.
ASLA "Harika bir CV", "Çok iyisin", "Mükemmel" gibi sahte övgüler yapma. Adayın eksiklerini net, sert ve yapıcı bir dille yüzüne vur.
Karşındaki kişi "{target_role}" ilanı için BAŞVURAN bir aday.
Adayın Deneyim Seviyesi: {experience_level}
Adayın Anlamsal Uyum (ATS) Skoru: {ats_score}/100.
Adayın Bildiği Tüm Yetenekler: {all_skills_str}
Adayın Sahip Olduğu Yetenekler (İlanla Eşleşen): {matched_str}
Adayın Eksik Olduğu (İlanda İstenen) Yetenekler: {missing_str}

Gelen iş ilanı metni hangi dilde olursa olsun, özetlemeyi KESİNLİKLE kullanıcının talep ettiği hedef dilde ({lang}) yap ve çevir. Sonuç her zaman hedef dilde olmalı.

Yanıtın KESİNLİKLE aşağıdaki 3 başlığı (tam olarak bu isimlerle) içermelidir ve profesyonel/sert bir dille ({lang}) yazılmalıdır:

1. Gerçekçi Uyum Analizi
CV ile ilan arasındaki uçurum nerede? Aday neden doğrudan reddedilebilir? (Lafı dolandırmadan net bir şekilde söyle). Eğer skor çok yüksekse bile rehavete kapılmaması gerektiğini söyle.

2. Kapatılması Gereken Açık
Eksik olan beceriler işin aslında ne işe yarıyor? Aday bu yetenekleri öğrenmek veya kanıtlamak için yarın sabah HANGİ SPESİFİK PROJEYE başlamalı? (Genel tavsiye verme, doğrudan teknik mimari veya proje adı ver. Eksik beceri yoksa bile adayı sınırlarını zorlayacak bir teknolojiye yönlendir).

3. CV İyileştirme (CV Rewriter)
Adayın sahip olduğu yeteneklerden birini seç. Sıradan bir cümleyi STAR (Situation, Task, Action, Result) tekniğiyle yazılmış, sayısal metrikler içeren profesyonel bir CV maddesine dönüştür.
Örnek format:
- Eski Hal: [Seçtiğin yetenekle ilgili sıradan bir cümle]
- Olması Gereken Hal: [STAR formatında, metrik içeren profesyonel cümle]

CRITICAL RULE: You MUST generate your entire response strictly in the following language code: '{lang}' (e.g., 'tr' for Turkish, 'de' for German, 'en' for English). Do not use any other language.
"""
    try:
        response = client.models.generate_content(model='gemini-2.5-flash', contents=prompt)
        return response.text.strip()
    except Exception as e:
        print(f"🚨 GEMINI HATASI (AI Koç): {str(e)}")
        return "Yapay zeka analizi şu an kullanılamıyor. Lütfen eksik becerilerinizi tamamlamaya odaklanın."


def generate_career_advice(job_matches: list, lang: str = "tr") -> dict:
    """Flutter arayüzüne gönderilecek nihai AI tavsiye paketini hazırlar."""
    if not job_matches:
        return {"summary": "Analiz edilecek eşleşme bulunamadı."}

    # En yüksek eşleşmeye sahip ilk ilanı hedef alıyoruz
    top_match = job_matches[0]
    target_role = top_match["job_title"]
    matched_skills = top_match.get("matched_skills", [])
    missing_skills = top_match["missing_skills"]
    ats_score = top_match.get("match_score_int", 0)

    # Gemini'den dinamik koçluk metnini (summary) al
    ai_summary = generate_ai_career_coach(target_role, matched_skills, missing_skills, ats_score, lang)

    # Flutter arayüzünün alt alta madde madde (bullet point) basabilmesi için
    # eksik yetenekleri JSON listesi formatında tutuyoruz.
    learning_path = [{"skill": skill} for skill in missing_skills]

    return {
        "target_role": target_role,
        "summary": ai_summary,
        "learning_path": learning_path,
    }