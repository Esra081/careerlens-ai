import sys
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.services import job_repository
from app.services.scorer import calculate_ats_score

def test_dynamic_scorer():
    print("Fetching jobs from repository...")
    total, jobs = job_repository.list_jobs(page=1, page_size=5)
    
    if not jobs:
        print("No jobs found in DB. Test aborted.")
        return
        
    job = jobs[0]
    job_skills = job.get("required_skills", [])
    
    # We provide a dummy CV with exactly one matching skill and one missing skill
    if len(job_skills) > 0:
        cv_skills = [job_skills[0], "DummySkill123"]
    else:
        job_skills = ["Python", "React", "Docker"]
        cv_skills = ["Python", "DummySkill123"]
        
    print(f"\n--- Testing Dynamic ATS Scorer ---")
    print(f"Target Job: {job['title']} at {job['company']}")
    print(f"Job Skills: {job_skills}")
    print(f"CV Skills: {cv_skills}")
    
    # Simulate a cosine similarity of 0.85
    dummy_cosine = 0.85
    
    result = calculate_ats_score(cv_skills, job_skills, dummy_cosine)
    
    print("\nResulting ATS Score Details:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    assert "ats_score" in result
    assert "matched_skills" in result
    assert "missing_skills" in result
    assert "details" in result
    
    print("\n✅ Dynamic ATS Score test passed successfully.")

if __name__ == "__main__":
    test_dynamic_scorer()
