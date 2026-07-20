# Önceden hazırlanmış yetenek havuzu (Skill Database)
SKILL_DB = [
    "Python", "Flutter", "Dart", "C++", "Java", "C#", 
    "YOLO", "OpenCV", "TensorFlow", "PyTorch", "Keras",
    "MATLAB", "Simulink", "Machine Learning", "Computer Vision", "Deep Learning",
    "Docker", "Kubernetes", "AWS", "GCP", "Azure",
    "FastAPI", "Django", "Flask", "PostgreSQL", "MongoDB", "Git"
]

def extract_skills(text: str) -> list:
    found_skills = []
    # Metni küçük harfe çevirerek büyük/küçük harf duyarlılığını ortadan kaldırıyoruz
    text_lower = text.lower()
    
    for skill in SKILL_DB:
        # Yetenek havuzundaki kelimeleri de küçük harfe çevirip metin içinde arıyoruz
        if skill.lower() in text_lower:
            found_skills.append(skill)
            
    return found_skills