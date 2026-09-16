import re
from app.services.ai_service import extract_skills_via_ai

# Fallback için temel yetenek kütüphanesi
FALLBACK_SKILLS = [
    "python", "java", "c++", "c#", "c", "javascript", "typescript", "ruby", "php", "swift", "kotlin", "go", "rust", "dart",
    "react", "angular", "vue", "django", "flask", "fastapi", "spring", "express", "node.js", "flutter", "react native",
    "sql", "mysql", "postgresql", "sqlite", "mongodb", "redis", "elasticsearch", "firebase", "oracle",
    "docker", "kubernetes", "aws", "azure", "gcp", "git", "github", "gitlab", "bitbucket", "jenkins", "ci/cd",
    "html", "css", "sass", "less", "bootstrap", "tailwind",
    "machine learning", "deep learning", "nlp", "computer vision", "data science", "pandas", "numpy", "scikit-learn", "tensorflow", "pytorch",
    "opencv", "yolo", "yolov8", "matlab", "simulink", "rest api", "graphql", "linux",
    "agile", "scrum", "kanban", "jira", "trello", "confluence"
]

def extract_skills(text: str) -> dict:
    """CV metninden Gemini (AI) kullanarak yetenekleri çıkarır. API çökerse veya boş dönerse kural tabanlı çıkarıma düşer."""
    try:
        res = extract_skills_via_ai(text)
        if res and res.get("skills") and len(res["skills"]) > 0:
            return res
        print("ℹ️ Gemini boş yetenek listesi döndü, kural tabanlı çıkarım devreye giriyor.")
    except Exception as e:
        print(f"🚨 YZ Çıkarımı Başarısız Oldu. Kaba Çıkarım (FALLBACK) Devrede. Hata: {str(e)}")

    text_lower = text.lower()
    extracted = []
    for skill in FALLBACK_SKILLS:
        pattern = r'(?<![a-zA-Z0-9])' + re.escape(skill) + r'(?![a-zA-Z0-9])'
        if re.search(pattern, text_lower):
            if skill in ["ci/cd", "sql", "aws", "gcp", "nlp", "html", "css"]:
                extracted.append(skill.upper())
            elif skill in ["c++", "c#", "node.js"]:
                extracted.append(skill.capitalize() if skill != "node.js" else "Node.js")
            elif skill in ["yolov8", "opencv", "scikit-learn", "pytorch", "fastapi"]:
                name_map = {
                    "yolov8": "YOLOv8",
                    "opencv": "OpenCV",
                    "scikit-learn": "Scikit-learn",
                    "pytorch": "PyTorch",
                    "fastapi": "FastAPI",
                }
                extracted.append(name_map.get(skill, skill.title()))
            else:
                extracted.append(skill.title())

    # Deneyim seviyesi tahmini
    exp_level = "Junior"
    if any(k in text_lower for k in ["senior", "lead", "principal", "yıl tecrübe", "years of experience"]):
        if any(f"{y}+" in text_lower or f"{y} yıl" in text_lower for y in ["5", "6", "7", "8", "10"]):
            exp_level = "Senior"
        else:
            exp_level = "Mid"

    return {"skills": extracted, "experience_level": exp_level}