import sys
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_pagination():
    print("Testing /api/v1/matches endpoint with pagination...")
    
    # We will pass dummy skills
    response = client.post("/api/v1/matches", json={"skills": ["Python", "React"], "limit": 5, "skip": 0})
    
    assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"
    
    data = response.json()
    assert "total" in data, "Response should contain 'total' field"
    assert "matches" in data, "Response should contain 'matches' field"
    
    matches = data["matches"]
    print(f"Total returned matches: {len(matches)}")
    print(f"Total matching jobs in DB: {data['total']}")
    
    # Verify limit works (should return exactly 5 jobs if DB has at least 5 matches)
    if data["total"] >= 5:
        assert len(matches) == 5, f"Expected 5 matches, got {len(matches)}"
    
    # Verify sorting (descending by score)
    scores = [match["match_score_int"] for match in matches]
    print(f"Scores returned: {scores}")
    
    # Check if scores are sorted descending
    assert scores == sorted(scores, reverse=True), "Matches are not sorted by score descending"
    
    # Verify /api/v1/jobs pagination
    print("\nTesting /api/v1/jobs endpoint with pagination...")
    job_response = client.get("/api/v1/jobs?limit=5&skip=0")
    assert job_response.status_code == 200
    
    job_data = job_response.json()
    assert job_data["skip"] == 0
    assert job_data["limit"] == 5
    assert len(job_data["jobs"]) <= 5
    print("Jobs pagination works correctly.")
    
    print("\n[SUCCESS] All pagination tests passed!")

if __name__ == "__main__":
    test_pagination()
