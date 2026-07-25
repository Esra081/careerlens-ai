import os
import requests
from dotenv import load_dotenv

load_dotenv(".env")
JOOBLE_API_KEY = os.getenv("JOOBLE_API_KEY")
ADZUNA_APP_ID = os.getenv("ADZUNA_APP_ID")
ADZUNA_APP_KEY = os.getenv("ADZUNA_APP_KEY")
CAREERJET_API_KEY = os.getenv("CAREERJET_API_KEY")

def test_jooble():
    if not JOOBLE_API_KEY:
        print("No Jooble key")
        return
    url = f"https://jooble.org/api/{JOOBLE_API_KEY}"
    payload = {"keywords": "yazılım geliştirici", "location": "Türkiye", "page": "1", "limit": "50"}
    res = requests.post(url, json=payload, headers={"Content-Type": "application/json"})
    jobs = res.json().get("jobs", [])
    print(f"Jooble (Türkiye) returned {len(jobs)} jobs")
    for j in jobs[:3]:
        print(f"  Location: {j.get('location')} | Snippet len: {len(j.get('snippet', ''))}")

    payload2 = {"keywords": "software developer", "location": "Turkey", "page": "1", "limit": "50"}
    res2 = requests.post(url, json=payload2, headers={"Content-Type": "application/json"})
    jobs2 = res2.json().get("jobs", [])
    print(f"Jooble (Turkey) returned {len(jobs2)} jobs")
    us_count = sum(1 for j in jobs2 if "NC" in j.get("location", "") or "North Carolina" in j.get("location", ""))
    print(f"  US locations found: {us_count}")
    
def test_adzuna():
    if not ADZUNA_APP_ID:
        return
    url = f"https://api.adzuna.com/v1/api/jobs/tr/search/1"
    params = {"app_id": ADZUNA_APP_ID, "app_key": ADZUNA_APP_KEY, "what": "software developer"}
    res = requests.get(url, params=params)
    jobs = res.json().get("results", [])
    print(f"Adzuna returned {len(jobs)} jobs")
    for j in jobs[:3]:
        print(f"  Location: {j.get('location', {}).get('display_name')} | Desc len: {len(j.get('description', ''))}")
        
test_jooble()
test_adzuna()
