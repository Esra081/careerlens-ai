def calculate_ats_score(extracted_skills: list, raw_text: str) -> dict:
    score = 0
    details = {}
    text_lower = raw_text.lower()

    # 1. Skill Match (Maks 40 Puan)
    # Şimdilik CV'de bulunan yetenek sayısına göre orantısal bir puan veriyoruz.
    # (İleride bunu bir iş ilanıyla eşleştirerek % üzerinden hesaplayacağız)
    skill_count = len(extracted_skills)
    skill_score = min(40, skill_count * 4)  # Her yetenek 4 puan, maks 40
    score += skill_score
    details["skill_match"] = f"{skill_score}/40"

    # 2. Deneyim (Maks 25 Puan)
    # Metin içinde deneyim, staj, "experience" gibi kelimeleri arıyoruz
    experience_keywords = [
        "deneyim", "tecrübe", "iş geçmişi", "görev", 
        "staj", "intern", "çalış", "work", "proje yürütücüsü"
    ]
    exp_score = 0
    if any(kw in text_lower for kw in experience_keywords):
        exp_score = 25
    score += exp_score
    details["experience"] = f"{exp_score}/25"

    # 3. Eğitim (Maks 15 Puan)
    edu_keywords = ["üniversite", "mühendislik", "lisans", "bachelor", "university"]
    edu_score = 0
    if any(kw in text_lower for kw in edu_keywords):
        edu_score = 15
    score += edu_score
    details["education"] = f"{edu_score}/15"

    # 4. Anahtar Kelimeler (Maks 20 Puan)
    # Sektörel buzzword'lerin (ör: proje, geliştirme, optimizasyon) varlığını kontrol ediyoruz
    buzzwords = ["geliştirme", "proje", "optimizasyon", "model", "algoritma", "ai"]
    buzz_count = sum(1 for bw in buzzwords if bw in text_lower)
    buzz_score = min(20, buzz_count * 5)
    score += buzz_score
    details["keywords"] = f"{buzz_score}/20"

    return {
        "total_score": score,
        "breakdown": details
    }