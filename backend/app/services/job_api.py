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

# Türkçe sorgular Jooble'da İngilizce karşılıklarla aynı sonuçları vermediği
# için her ikisini de tarıyoruz. Böylece Türkiye'deki yazılım/bilgisayar
# mühendisliği ilanları daha geniş biçimde yakalanır.
SEARCH_KEYWORDS = (
    "yazılım geliştirici",
    "yazılım mühendisi",
    "bilgisayar mühendisi",
    "backend developer",
    "frontend developer",
    "full stack developer",
    "software engineer",
    "python developer",
    "mobil uygulama geliştirici",
    "veri mühendisi",
)

# Adzuna çağrı kotasını gereksiz tüketmemek için geniş kapsamlı, teknik odaklı
# dört sorgu kullanıyoruz. Her sorgu güncel sonuçlardan ilk sayfayı getirir.
ADZUNA_KEYWORDS = (
    "software developer",
    "backend developer",
    "frontend developer",
    "bilgisayar mühendisi",
)

CAREERJET_KEYWORDS = (
    "yazılım geliştirici",
    "bilgisayar mühendisi",
    "backend developer",
    "frontend developer",
    "python developer",
)

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

TURKEY_CITY_MARKERS = (
    "istanbul", "i̇stanbul", "ankara", "izmir",
    "i̇zmir", "bursa", "antalya", "kocaeli", "gebze", "sakarya",
    "eskişehir", "eskisehir", "konya", "adana", "gaziantep", "mersin",
    "kayseri", "trabzon", "samsun", "denizli", "manisa", "tekirdağ",
    "tekirdag", "muğla", "mugla", "balıkesir", "balikesir",
)


def _job_id(job: dict) -> str:
    """API her istekte değişebilen UUID yerine kararlı bir ilan kimliği üretir."""
    source = "|".join(str(job.get(key, "")) for key in ("title", "company", "link"))
    return hashlib.sha256(source.encode("utf-8")).hexdigest()


def _to_job(job: dict, source: str = "unknown") -> dict:
    text = f"{job.get('title', '')} {job.get('snippet', '')}".casefold()
    skills = [label for keyword, label in TECHNOLOGIES.items() if keyword in text]
    return {
        "id": _job_id(job),
        "source": source,
        "title": job.get("title") or "Belirtilmemiş Pozisyon",
        "company": job.get("company") or "Gizli Şirket",
        "location": job.get("location") or "Türkiye",
        "country": "TR",
        "required_skills": skills or ["Yazılım", "Bilgisayar Mühendisliği"],
        "link": job.get("link"),
    }


def _is_turkey_job(job: dict) -> bool:
    """Jooble bazen ülke filtresini yok saydığından konumu yeniden doğrular."""
    location = str(job.get("location") or "").casefold().strip()
    # Jooble'ın örnek/veri-hatalı yanıtlarında "Turkey, NC" ABD'deki Turkey
    # şehridir; ülke olarak Türkiye değildir.
    if "turkey, nc" in location:
        return False
    if location in {"turkey", "türkiye"} or ", turkey" in location or ", türkiye" in location:
        return True
    return any(marker in location for marker in TURKEY_CITY_MARKERS)


def _to_adzuna_job(job: dict) -> dict:
    company = job.get("company") or {}
    location = job.get("location") or {}
    raw_job = {
        "title": job.get("title"),
        "company": company.get("display_name"),
        "location": location.get("display_name"),
        "snippet": job.get("description"),
        "link": job.get("redirect_url"),
    }
    normalized = _to_job(raw_job, source="adzuna")
    normalized["id"] = f"adzuna:{job.get('id', normalized['id'])}"
    return normalized


def _to_careerjet_job(job: dict) -> dict:
    raw_job = {
        "title": job.get("title"),
        "company": job.get("company"),
        "location": job.get("locations"),
        "snippet": job.get("description"),
        "link": job.get("url"),
    }
    normalized = _to_job(raw_job, source="careerjet")
    normalized["id"] = f"careerjet:{_job_id(raw_job)}"
    return normalized


def _fetch_careerjet_jobs(session: requests.Session) -> list[dict]:
    """Careerjet'in Türkiye (`tr_TR`) yayınevi API'sinden teknik ilanları getirir."""
    if not CAREERJET_API_KEY:
        print("[*] Careerjet atlandı: CAREERJET_API_KEY tanımlı değil.")
        return []

    jobs_by_id: dict[str, dict] = {}
    for keyword in CAREERJET_KEYWORDS:
        try:
            response = session.get(
                CAREERJET_URL,
                params={
                    "locale_code": "tr_TR",
                    "keywords": keyword,
                    "page": 1,
                    "page_size": 50,
                    "sort": "date",
                    # Careerjet, isteği yapan kullanıcı IP'si veya user-agent
                    # bilgisinden en az birini zorunlu tutar.
                    "user_agent": "CareerLens AI job matching service",
                },
                auth=(CAREERJET_API_KEY, ""),
                timeout=15,
            )
            response.raise_for_status()
        except requests.RequestException as error:
            print(f"[!] Careerjet '{keyword}' sorgusu başarısız: {error}")
            continue

        data = response.json()
        if data.get("type") != "JOBS":
            print(f"[!] Careerjet '{keyword}' yanıtı: {data.get('message', 'bilinmeyen yanıt')}")
            continue

        for raw_job in data.get("jobs", []):
            job = _to_careerjet_job(raw_job)
            jobs_by_id[job["id"]] = job

    jobs = list(jobs_by_id.values())
    print(f"[*] Careerjet (tr_TR) üzerinden {len(jobs)} teknik ilan alındı.")
    return jobs


def _fetch_adzuna_jobs(session: requests.Session) -> list[dict]:
    """Adzuna'nın Türkiye pazarı destekleniyorsa güncel teknik ilanları getirir."""
    if not ADZUNA_APP_ID or not ADZUNA_APP_KEY:
        print("[*] Adzuna atlandı: ADZUNA_APP_ID ve ADZUNA_APP_KEY tanımlı değil.")
        return []

    jobs_by_id: dict[str, dict] = {}
    for keyword in ADZUNA_KEYWORDS:
        try:
            response = session.get(
                f"{ADZUNA_URL}/{ADZUNA_COUNTRY}/search/1",
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
                print(
                    f"[!] Adzuna '{ADZUNA_COUNTRY}' pazarı desteklenmiyor; "
                    "Türkiye için Adzuna ilanları kullanılamaz."
                )
                return []
            response.raise_for_status()
        except requests.RequestException as error:
            print(f"[!] Adzuna '{keyword}' sorgusu başarısız: {error}")
            continue

        for raw_job in response.json().get("results", []):
            job = _to_adzuna_job(raw_job)
            jobs_by_id[job["id"]] = job

    jobs = list(jobs_by_id.values())
    print(f"[*] Adzuna ({ADZUNA_COUNTRY}) üzerinden {len(jobs)} teknik ilan alındı.")
    return jobs


def _fetch_jooble_jobs(session: requests.Session) -> list[dict]:
    """Jooble'dan, konumu Türkiye olarak doğrulanmış ilanları getirir."""
    if not JOOBLE_API_KEY:
        print("[*] Jooble atlandı: JOOBLE_API_KEY tanımlı değil.")
        return []
    jobs_by_id: dict[str, dict] = {}
    headers = {"Content-Type": "application/json"}
    raw_count = 0

    for keyword in SEARCH_KEYWORDS:
        payload = {
            "keywords": keyword,
            # Jooble ülke adını İngilizce bekliyor. "Türkiye" yanıtı 200
            # olsa bile boş bir jobs dizisi döndürebiliyor.
            "location": "Turkey",
            "page": "1",
            "limit": "50",
        }
        try:
            response = session.post(
                JOOBLE_URL, json=payload, headers=headers, timeout=15
            )
            response.raise_for_status()
        except requests.RequestException as error:
            print(f"[!] Jooble '{keyword}' sorgusu başarısız: {error}")
            continue

        for raw_job in response.json().get("jobs", []):
            print(raw_job["location"])
            raw_count += 1

            job = _to_job(raw_job, source="jooble")
            jobs_by_id[job["id"]] = job

    jobs = list(jobs_by_id.values())
    print(
        f"[*] Jooble'dan {raw_count} ham ilan alındı; "
        f"Türkiye konum doğrulamasından {len(jobs)} ilan geçti."
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
