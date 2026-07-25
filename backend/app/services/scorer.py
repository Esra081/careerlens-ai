def calculate_ats_score(cv_skills: list, job_skills: list, cosine_similarity: float) -> dict:
    """
    CV yetenekleri ile hedef iş ilanı yeteneklerini karşılaştırarak dinamik ATS skoru hesaplar.
    Skor Ağırlığı: %60 Kosinüs Benzerliği (Anlamsal Uyum), %40 Beceri Eşleşmesi (Keyword Match)
    """
    cv_set = set(s.lower() for s in cv_skills)
    job_set = set(s.lower() for s in job_skills)
    
    # Keyword (Beceri) Eşleşmesi Skoru (%40)
    if not job_set:
        keyword_score = 40  # İlanın belirgin bir yeteneği yoksa tam puan verilebilir
    else:
        matched_count = len(cv_set.intersection(job_set))
        keyword_score = int((matched_count / len(job_set)) * 40)
        
    # Anlamsal (Semantic) Skor (%60)
    semantic_score = max(0, int(cosine_similarity * 60))
    
    total_score = semantic_score + keyword_score
    
    # Orjinal casing'leri korumak için job_skills üzerinden mapping yapıyoruz
    job_casing = {s.lower(): s for s in job_skills}
    
    matched_skills = [job_casing[s] for s in cv_set.intersection(job_set) if s in job_casing]
    missing_skills = [job_casing[s] for s in job_set.difference(cv_set) if s in job_casing]
    
    return {
        "ats_score": total_score,
        "matched_skills": matched_skills,
        "missing_skills": missing_skills,
        "details": {
            "semantic_score": f"{semantic_score}/60",
            "keyword_score": f"{keyword_score}/40"
        }
    }