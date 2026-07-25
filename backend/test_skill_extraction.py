import sys
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.services.extractor import extract_skills

def run_test():
    dummy_cv = "Ben JavaScript, HTML, CSS konusunda deneyimliyim."
    print("Testing CV extraction with text:", dummy_cv)
    
    skills = extract_skills(dummy_cv)
    print("Extracted skills:", skills)
    
    assert isinstance(skills, list), "Output should be a list"
    
    # Check that 'Java' is NOT in the list (case-insensitive check just in case)
    lower_skills = [s.lower() for s in skills]
    assert "java" not in lower_skills, "False positive detected: 'Java' was extracted from 'JavaScript'!"
    assert "javascript" in lower_skills, "'JavaScript' should be extracted!"
    
    print("✅ Test passed! False-positive 'Java' problem is solved.")

if __name__ == "__main__":
    run_test()
