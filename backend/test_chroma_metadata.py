import sys
from pathlib import Path

# Backend yolunu ekle ki app modülünü bulabilelim
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.services.matcher import refresh_embeddings, calculate_job_match

def test_chroma():
    print("=== Refreshing Embeddings ===")
    count = refresh_embeddings()
    print(f"Refreshed {count} embeddings in ChromaDB.")

    if count == 0:
        print("No jobs in SQLite to test. Please run ingest first.")
        return

    print("\n=== Testing Job Match (Country: US) ===")
    us_matches = calculate_job_match(
        cv_skills=["react", "python", "javascript", "full stack"],
        cv_text="I am a software engineer with 5 years of experience building web applications.",
        country="US"
    )
    
    print(f"Total matches for US: {len(us_matches)}")
    for m in us_matches:
        print(f"  Title: {m['job_title']} | Location: {m['location']} | Score: {m['match_percentage']}")

    print("\n=== Testing Job Match (Country: TR) ===")
    tr_matches = calculate_job_match(
        cv_skills=["react", "python", "javascript", "full stack"],
        cv_text="I am a software engineer with 5 years of experience building web applications.",
        country="TR"
    )
    
    print(f"Total matches for TR: {len(tr_matches)}")
    for m in tr_matches:
        print(f"  Title: {m['job_title']} | Location: {m['location']} | Score: {m['match_percentage']}")

if __name__ == "__main__":
    test_chroma()
