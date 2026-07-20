import json
import os

# CV verisinin tutulacağı dosya yolu
CV_FILE = "user_cv.json"

def save_cv(cv_data):
    """CV verisini dosyaya kaydeder."""
    with open(CV_FILE, "w", encoding="utf-8") as f:
        json.dump(cv_data, f, indent=4)
    print("[*] CV başarıyla kaydedildi.")

def get_saved_cv():
    """Dosyadaki CV verisini okur."""
    if os.path.exists(CV_FILE):
        with open(CV_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return None