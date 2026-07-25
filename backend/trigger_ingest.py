import sys
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.main import ingest_jobs
from app.services.job_repository import job_count

def run():
    print("Starting full ingest process...")
    result = ingest_jobs()
    print("Ingest process completed!")
    print("Result:", result)
    print("Total jobs in database:", job_count())

if __name__ == "__main__":
    run()
