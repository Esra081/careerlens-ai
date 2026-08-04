import hashlib
import os
from pathlib import Path

import requests
from dotenv import load_dotenv

# Backend terminaliyle başlatıldığında kök dizindeki .env dosyasını da yükle.
load_dotenv(Path(__file__).resolve().parents[3] / ".env")

JOOBLE_API_KEY = os.getenv("JOOBLE_API_KEY")
if not JOOBLE_API_KEY:
    print("[!] UYARI: JOOBLE_API_KEY ortam değişkeni tanımlı değil. Jooble ilanları çekilemeyecek.")
JOOBLE_URL = f"https://jooble.org/api/{JOOBLE_API_KEY}" if JOOBLE_API_KEY else ""
ADZUNA_APP_ID = os.getenv("ADZUNA_APP_ID")
ADZUNA_APP_KEY = os.getenv("ADZUNA_APP_KEY")
ADZUNA_COUNTRY = os.getenv("ADZUNA_COUNTRY", "tr")
ADZUNA_URL = "https://api.adzuna.com/v1/api/jobs"
CAREERJET_API_KEY = os.getenv("CAREERJET_API_KEY")
CAREERJET_URL = "https://search.api.careerjet.net/v4/query"

TARGET_COUNTRIES = ["TR", "US", "UK", "DE"]

COUNTRY_CONFIG = {
    "TR": {
        "keywords": ["yazılım geliştirici", "bilgisayar mühendisi", "backend developer", "frontend developer", "python developer"],
        "adzuna_code": "tr",
        "careerjet_locale": "tr_TR",
        "jooble_location": "Türkiye",
    },
    "US": {
        "keywords": ["software engineer", "backend developer", "frontend developer", "full stack developer", "python developer"],
        "adzuna_code": "us",
        "careerjet_locale": "en_US",
        "jooble_location": "USA",
    },
    "UK": {
        "keywords": ["software engineer", "backend developer", "frontend developer", "full stack developer", "python developer"],
        "adzuna_code": "gb",
        "careerjet_locale": "en_GB",
        "jooble_location": "United Kingdom",
    },
    "DE": {
        "keywords": ["software engineer", "backend developer", "frontend developer", "softwareentwickler", "python developer"],
        "adzuna_code": "de",
        "careerjet_locale": "de_DE",
        "jooble_location": "Germany",
    }
}

TECHNOLOGIES = {
    "python": "Python", "java": "Java", "javascript": "JavaScript",
    "typescript": "TypeScript", "c++": "C++", "c#": "C#",
    "react": "React", "angular": "Angular", "flutter": "Flutter",
    "dart": "Dart", "node.js": "Node.js", "nodejs": "Node.js",
    "sql": "SQL", "postgresql": "PostgreSQL", "mongodb": "MongoDB",
    "docker": "Docker", "kubernetes": "Kubernetes", "aws": "AWS",
    "azure": "Azure", "git": "Git", "linux": "Linux", "api": "API",
    "machine learning": "Machine Learning", "yapay zeka": "Yapay Zeka",
    "artificial intelligence": "Yapay Zeka", "opencv": "OpenCV",
    "pytorch": "PyTorch", "tensorflow": "TensorFlow",
}


def _job_id(job: dict) -> str:
    """API her istekte değişebilen UUID yerine kararlı bir ilan kimliği üretir."""
    source = "|".join(str(job.get(key, "")) for key in ("title", "company", "link"))
    return hashlib.sha256(source.encode("utf-8")).hexdigest()


import re

def normalize_country_code(location_str: str, fallback_country: str = "UNKNOWN") -> str:
    """Lokasyon metnine göre ilanın ait olduğu ülkeyi ISO kodu olarak belirler."""
    loc = str(location_str).casefold()
    if not loc:
        return fallback_country

    # TR markers
    if any(m in loc for m in ["istanbul", "ankara", "izmir", "türkiye", "turkey", "bursa", "antalya"]):
        return "TR"
    # UK markers
    if any(m in loc for m in ["uk", "united kingdom", "london", "england", "scotland", "birmingham"]):
        return "UK"
    # DE markers
    if any(m in loc for m in ["germany", "deutschland", "berlin", "munich", "hamburg", "frankfurt"]):
        return "DE"
    # US markers (States and common terms)
    if any(m in loc for m in ["usa", "united states", "new york", "california", "texas", "florida", " nc", ", nc", " tx", ", tx", " ca", ", ca", " ny", ", ny", " il", ", il"]):
        return "US"
        
    return fallback_country

def _to_job(job: dict, source: str, raw_desc: str, target_country: str) -> dict:
    # HTML tag'lerini temizle
    clean_desc = re.sub(r'<[^>]+>', '', raw_desc).strip()
    
    # Kelime sınırı ile arama
    text = f"{job.get('title', '')} {clean_desc}".casefold()
    skills = []
    for keyword, label in TECHNOLOGIES.items():
        if re.search(r'\b' + re.escape(keyword) + r'\b', text):
            if label not in skills:
                skills.append(label)
                
    # Country'yi gerçeğinden türet (Aksi takdirde hedeflenen ülke kalır)
    country = normalize_country_code(job.get('location', ''), fallback_country=target_country)

    return {
        "id": _job_id(job),
        "source": source,
        "title": job.get("title") or "Belirtilmemiş Pozisyon",
        "company": job.get("company") or "Gizli Şirket",
        "location": job.get("location") or "Belirtilmemiş",
        "country": country,
        "description": clean_desc,
        "required_skills": skills,
        "link": job.get("link"),
    }


def _to_adzuna_job(job: dict, target_country: str) -> dict:
    company = job.get("company") or {}
    location = job.get("location") or {}
    raw_job = {
        "title": job.get("title"),
        "company": company.get("display_name"),
        "location": location.get("display_name"),
        "link": job.get("redirect_url"),
    }
    normalized = _to_job(raw_job, source="adzuna", raw_desc=job.get("description", ""), target_country=target_country)
    normalized["id"] = f"adzuna:{job.get('id', normalized['id'])}"
    
    try:
        s_min = float(job.get("salary_min") or 0)
        s_max = float(job.get("salary_max") or 0)
        if s_min > 0 and s_max > 0:
            normalized["salary"] = f"{int(s_min)} - {int(s_max)}"
            print(f"💰 [MAAŞ RADARI] Adzuna İlanı: {job.get('title')} | Maaş: {s_min} - {s_max}")
    except ValueError:
        pass

    return normalized


def _to_careerjet_job(job: dict, target_country: str) -> dict:
    raw_job = {
        "title": job.get("title"),
        "company": job.get("company"),
        "location": job.get("locations"),
        "link": job.get("url"),
    }
    normalized = _to_job(raw_job, source="careerjet", raw_desc=job.get("description", ""), target_country=target_country)
    normalized["id"] = f"careerjet:{_job_id(raw_job)}"
    return normalized


def _fetch_careerjet_jobs(session: requests.Session) -> list[dict]:
    print("[*] Careerjet API'si (403 hatası nedeniyle) geçici olarak devre dışı bırakıldı.")
    return []

    if not CAREERJET_API_KEY:
        print("[*] Careerjet atlandı: CAREERJET_API_KEY tanımlı değil.")
        return []

    jobs_by_id: dict[str, dict] = {}
    
    for country in TARGET_COUNTRIES:
        config = COUNTRY_CONFIG[country]
        locale = config["careerjet_locale"]
        
        for keyword in config["keywords"]:
            try:
                response = session.get(
                    CAREERJET_URL,
                    params={
                        "locale_code": locale,
                        "keywords": keyword,
                        "page": 1,
                        "page_size": 50,
                        "sort": "date",
                        "user_ip": "88.236.45.101",
                        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
                    },
                    auth=(CAREERJET_API_KEY, ""),
                    timeout=15,
                )
                response.raise_for_status()
            except requests.RequestException as error:
                if hasattr(error, 'response') and error.response is not None and error.response.status_code == 403:
                    print(f"[!] Careerjet 403 Forbidden hatası verdi. Parametreler kabul edilmedi, Careerjet atlanıyor.")
                    return []
                print(f"[!] Careerjet ({country}) '{keyword}' sorgusu başarısız: {error}")
                continue

            data = response.json()
            if data.get("type") != "JOBS":
                continue

            for raw_job in data.get("jobs", []):
                job = _to_careerjet_job(raw_job, target_country=country)
                jobs_by_id[job["id"]] = job

    jobs = list(jobs_by_id.values())
    valid_desc_count = sum(1 for j in jobs if len(j["description"]) > 20)
    print(f"[*] Careerjet üzerinden {len(jobs)} ilan alındı. (Açıklaması dolu olanlar: {valid_desc_count})")
    return jobs


def _fetch_adzuna_jobs(session: requests.Session) -> list[dict]:
    if not ADZUNA_APP_ID or not ADZUNA_APP_KEY:
        print("[*] Adzuna atlandı: ADZUNA_APP_ID ve ADZUNA_APP_KEY tanımlı değil.")
        return []

    jobs_by_id: dict[str, dict] = {}
    
    for country in TARGET_COUNTRIES:
        config = COUNTRY_CONFIG[country]
        adzuna_code = config["adzuna_code"]
        
        for keyword in config["keywords"]:
            try:
                response = session.get(
                    f"{ADZUNA_URL}/{adzuna_code}/search/1",
                    params={
                        "app_id": ADZUNA_APP_ID,
                        "app_key": ADZUNA_APP_KEY,
                        "what": keyword,
                        "results_per_page": 50,
                        "content-type": "application/json",
                    },
                    timeout=15,
                )
                if response.status_code == 404:
                    print(f"[!] Adzuna '{adzuna_code}' pazarı desteklenmiyor, atlanıyor.")
                    break  # This country is not supported, skip other keywords
                response.raise_for_status()
            except requests.RequestException as error:
                print(f"[!] Adzuna ({country}) '{keyword}' sorgusu başarısız: {error}")
                continue

            for raw_job in response.json().get("results", []):
                job = _to_adzuna_job(raw_job, target_country=country)
                jobs_by_id[job["id"]] = job

    jobs = list(jobs_by_id.values())
    valid_desc_count = sum(1 for j in jobs if len(j["description"]) > 20)
    print(f"[*] Adzuna üzerinden {len(jobs)} ilan alındı. (Açıklaması dolu olanlar: {valid_desc_count})")
    return jobs


def _fetch_jooble_jobs(session: requests.Session) -> list[dict]:
    if not JOOBLE_API_KEY:
        print("[*] Jooble atlandı: JOOBLE_API_KEY tanımlı değil.")
        return []
    jobs_by_id: dict[str, dict] = {}
    headers = {"Content-Type": "application/json"}
    raw_count = 0

    for country in TARGET_COUNTRIES:
        config = COUNTRY_CONFIG[country]
        location_str = config["jooble_location"]
        
        for keyword in config["keywords"]:
            payload = {
                "keywords": keyword,
                "location": location_str,
                "page": "1",
                "limit": "50",
            }
            try:
                response = session.post(
                    JOOBLE_URL, json=payload, headers=headers, timeout=15
                )
                response.raise_for_status()
            except requests.RequestException as error:
                print(f"[!] Jooble ({country}) '{keyword}' sorgusu başarısız: {error}")
                continue

            for raw_job in response.json().get("jobs", []):
                raw_count += 1
                job = _to_job(raw_job, source="jooble", raw_desc=raw_job.get("snippet", ""), target_country=country)
                raw_salary = raw_job.get("salary")
                if raw_salary and str(raw_salary).strip():
                    job["salary"] = str(raw_salary).strip()
                    print(f"💰 [JOOBLE MAAŞ RADARI] Jooble İlanı: {job.get('title')} | Maaş: {job['salary']}")
                else:
                    job["salary"] = None
                jobs_by_id[job["id"]] = job

    jobs = list(jobs_by_id.values())
    valid_desc_count = sum(1 for j in jobs if len(j["description"]) > 20)
    print(
        f"[*] Jooble'dan {raw_count} ham ilan alındı; "
        f"toplam {len(jobs)} ilan normalize edildi. (Açıklaması dolu olanlar: {valid_desc_count})"
    )
    return jobs


def fetch_real_jobs() -> list[dict]:
    """Adzuna ve Jooble'dan yinelenmeyen güncel Türkiye teknik ilanlarını getirir."""
    session = requests.Session()
    # Bazı geliştirme ortamlarında tanımlı hatalı HTTP(S)_PROXY değişkenleri
    # Jooble isteğini 127.0.0.1'e yönlendirip bağlantıyı kesebiliyor.
    session.trust_env = False

    jobs_by_id: dict[str, dict] = {}
    for job in (
        _fetch_careerjet_jobs(session)
        + _fetch_adzuna_jobs(session)
        + _fetch_jooble_jobs(session)
    ):
        # Kaynaklar arası aynı ilanı başlık + şirket üzerinden tekilleştir.
        duplicate_key = f"{job['title'].casefold()}|{job['company'].casefold()}"
        jobs_by_id.setdefault(duplicate_key, job)

    jobs = list(jobs_by_id.values())
    print(f"[*] Toplam {len(jobs)} doğrulanmış güncel teknik ilan hazır.")
    return jobs
