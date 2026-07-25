import re
from app.services.ai_service import extract_skills_via_ai

# Fallback için temel yetenek kütüphanesi
FALLBACK_SKILLS = [
    "python", "java", "c++", "c#", "javascript", "typescript", "ruby", "php", "swift", "kotlin", "go", "rust",
    "react", "angular", "vue", "django", "flask", "spring", "express", "node.js", "flutter", "react native",
    "sql", "mysql", "postgresql", "mongodb", "redis", "elasticsearch", "firebase", "oracle",
    "docker", "kubernetes", "aws", "azure", "gcp", "git", "github", "gitlab", "bitbucket", "jenkins", "ci/cd",
    "html", "css", "sass", "less", "bootstrap", "tailwind",
    "machine learning", "deep learning", "nlp", "computer vision", "data science", "pandas", "numpy", "scikit-learn", "tensorflow", "pytorch",
    "agile", "scrum", "kanban", "jira", "trello", "confluence"
]

def extract_skills(text: str) -> list:
    """CV metninden Gemini (AI) kullanarak yetenekleri çıkarır. API çökerse basit kelime eşleştirmeye düşer."""
    try:
        return extract_skills_via_ai(text)
    except Exception as e:
        print(f"🚨 YZ Çıkarımı Başarısız Oldu. Kaba Çıkarım (FALLBACK) Devrede. Hata: {str(e)}")
        text_lower = text.lower()
        extracted = []
        for skill in FALLBACK_SKILLS:
            # Sadece tam kelime eşleşmelerini al (ör: 'go' -> 'google' içinden çıkmasın)
            pattern = r'\b' + re.escape(skill) + r'\b'
            if re.search(pattern, text_lower):
                # Orijinal formatta göstermek için ilk harfini büyüt, ci/cd gibi özel kelimeleri koru
                extracted.append("CI/CD" if skill == "ci/cd" else skill.title())
        return extracted