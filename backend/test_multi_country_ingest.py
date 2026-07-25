import sys
import os
from pathlib import Path
import requests

# Backend yolunu ekle ki app modülünü bulabilelim
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.services.job_api import _fetch_jooble_jobs, _fetch_careerjet_jobs, fetch_real_jobs
from app.services.job_repository import upsert_jobs, list_jobs

def test_multi_country():
    session = requests.Session()
    session.trust_env = False
    
    print("=== Testing Jooble ===")
    try:
        jooble_jobs = _fetch_jooble_jobs(session)
        print(f"Total Jooble jobs: {len(jooble_jobs)}")
        
        tr_jobs = [j for j in jooble_jobs if j["country"] == "TR"]
        us_jobs = [j for j in jooble_jobs if j["country"] == "US"]
        
        if tr_jobs:
            print("\nSample TR Job (Jooble):")
            print(f"  Title: {tr_jobs[0]['title']}")
            print(f"  Country: {tr_jobs[0]['country']}")
            print(f"  Location: {tr_jobs[0]['location']}")
            
        if us_jobs:
            print("\nSample US Job (Jooble):")
            print(f"  Title: {us_jobs[0]['title']}")
            print(f"  Country: {us_jobs[0]['country']}")
            print(f"  Location: {us_jobs[0]['location']}")
            
    except Exception as e:
        print(f"Jooble test failed: {e}")

    print("\n=== Testing Careerjet ===")
    try:
        cj_jobs = _fetch_careerjet_jobs(session)
        print(f"Total Careerjet jobs: {len(cj_jobs)}")
        
        tr_jobs_cj = [j for j in cj_jobs if j["country"] == "TR"]
        us_jobs_cj = [j for j in cj_jobs if j["country"] == "US"]
        
        if tr_jobs_cj:
            print("\nSample TR Job (Careerjet):")
            print(f"  Title: {tr_jobs_cj[0]['title']}")
            print(f"  Country: {tr_jobs_cj[0]['country']}")
            
        if us_jobs_cj:
            print("\nSample US Job (Careerjet):")
            print(f"  Title: {us_jobs_cj[0]['title']}")
            print(f"  Country: {us_jobs_cj[0]['country']}")
            
    except Exception as e:
        print(f"Careerjet test failed: {e}")
        
    print("\n=== Testing SQLite Schema ===")
    # Sadece 1 tane örnek veriyi SQLite'a yazıp okumayı deneyelim
    sample_jobs = []
    if 'jooble_jobs' in locals() and jooble_jobs:
        sample_jobs.extend(jooble_jobs[:2])
    if 'cj_jobs' in locals() and cj_jobs:
        sample_jobs.extend(cj_jobs[:2])
        
    if sample_jobs:
        upserted = upsert_jobs(sample_jobs)
        print(f"Upserted {upserted} sample jobs into SQLite.")
        
        total, read_jobs = list_jobs(page_size=5)
        print(f"Successfully read back from DB. Validating country fields:")
        for job in read_jobs[:2]:
            print(f"  ID: {job['id']}, Country: {job['country']}, Title: {job['title']}")
    else:
        print("No jobs fetched to test SQLite schema.")

if __name__ == "__main__":
    test_multi_country()
