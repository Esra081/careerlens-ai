# 📡 CareerLens AI — REST API Dokümantasyonu

CareerLens AI arka uç (backend) servisi FastAPI ile geliştirilmiş olup standart REST ilkelerini ve OpenAPI/Swagger spesifikasyonunu destekler.

- **Base URL:** `http://localhost:8000` veya yerel ağ IP'si
- **Etkileşimli Swagger Dokümanı:** `http://localhost:8000/docs`
- **ReDoc Dokümanı:** `http://localhost:8000/redoc`

---

## 1. Kimlik Doğrulama (Authentication)

### 1.1 Yeni Kullanıcı Kaydı (Register)
- **URL:** `/api/v1/auth/register`
- **Method:** `POST`
- **İçerik Türü:** `application/json`

#### Request Body:
```json
{
  "full_name": "Esra Kılıç",
  "email": "esra@example.com",
  "password": "guclu_sifre_123"
}
```

#### Response (201 Created):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "c7a8b9f0-1234-4567-89ab-cdef01234567",
    "email": "esra@example.com",
    "full_name": "Esra Kılıç",
    "fcm_token": null,
    "created_at": "2026-09-13T10:30:00Z"
  }
}
```

---

### 1.2 Kullanıcı Girişi (Login)
- **URL:** `/api/v1/auth/login`
- **Method:** `POST`
- **İçerik Türü:** `application/json`

#### Request Body:
```json
{
  "email": "esra@example.com",
  "password": "guclu_sifre_123"
}
```

#### Response (200 OK):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "c7a8b9f0-1234-4567-89ab-cdef01234567",
    "email": "esra@example.com",
    "full_name": "Esra Kılıç",
    "fcm_token": "device_token_xyz",
    "created_at": "2026-09-13T10:30:00Z"
  }
}
```

---

### 1.3 Mevcut Profil Bilgisi (Me)
- **URL:** `/api/v1/auth/me`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <access_token>`

#### Response (200 OK):
```json
{
  "id": "c7a8b9f0-1234-4567-89ab-cdef01234567",
  "email": "esra@example.com",
  "full_name": "Esra Kılıç",
  "fcm_token": "device_token_xyz",
  "created_at": "2026-09-13T10:30:00Z"
}
```

---

## 2. CV Analizi ve Eşleştirme (CV & Job Matching)

### 2.1 Tam CV Analiz Pipeline'ı
- **URL:** `/api/v1/analyze-cv`
- **Method:** `POST`
- **İçerik Türü:** `multipart/form-data`
- **Query Parametreleri:** `country=ALL` (veya TR, US, UK, DE), `lang=tr` (veya en)

#### Form Data:
- `file`: PDF dosyası (Binary, max 10MB)

#### Response (200 OK):
```json
{
  "status": "success",
  "data": {
    "parsed_skills": ["Python", "Flutter", "FastAPI", "Docker", "SQL"],
    "experience_level": "Junior",
    "ats_score": {
      "ats_score": 82,
      "matched_skills": ["Python", "FastAPI", "SQL"],
      "missing_skills": ["Kubernetes", "Redis"],
      "details": {
        "semantic_score": "48/60",
        "keyword_score": "34/40"
      }
    },
    "job_matches": [
      {
        "id": "job_12345",
        "job_title": "Junior Python / Backend Developer",
        "company": "Tech Corp",
        "location": "İstanbul (Hibrit)",
        "url": "https://example.com/apply",
        "match_score_int": 82,
        "match_percentage": "%82",
        "matched_skills": ["Python", "FastAPI", "SQL"],
        "missing_skills": ["Kubernetes", "Redis"],
        "salary": "40.000 - 55.000 TL"
      }
    ],
    "career_advice": {
      "target_role": "Junior Python / Backend Developer",
      "summary": "1. Gerçekçi Uyum Analizi: ...\n2. Kapatılması Gereken Açık: ...\n3. CV İyileştirme: ...",
      "learning_path": [{"skill": "Kubernetes"}, {"skill": "Redis"}]
    }
  }
}
```

---

### 2.2 Yeteneklere Göre İlan Eşleştirme (Matches)
- **URL:** `/api/v1/matches`
- **Method:** `POST`
- **İçerik Türü:** `application/json`

#### Request Body:
```json
{
  "skills": ["Python", "Flutter", "FastAPI"],
  "experience_level": "Junior",
  "country": "TR",
  "skip": 0,
  "limit": 20,
  "experience": "junior",
  "work_model": "remote",
  "min_salary": 30000
}
```

---

## 3. Yapay Zeka Kariyer Asistanı (AI Coach & Bullet Rewriter)

### 3.1 CV Cümlesi İyileştirme (STAR Bullet Rewriter)
- **URL:** `/api/v1/ai/rewrite`
- **Method:** `POST`

#### Request Body:
```json
{
  "old_sentence": "Python ile backend API geliştirdim.",
  "lang": "tr"
}
```

#### Response (200 OK):
```json
{
  "old_sentence": "Python ile backend API geliştirdim.",
  "improved_sentence": "FastAPI ve Python kullanarak yüksek verimli REST API mimarisi tasarlandı; veri tabanı sorgu optimizasyonuyla yanıt süreleri %35 iyileştirildi."
}
```

### 3.2 Dinamik AI Kariyer Mentorluğu
- **URL:** `/api/v1/ai/coach`
- **Method:** `POST`

#### Request Body:
```json
{
  "target_role": "Backend Engineer",
  "matched_skills": ["Python", "FastAPI"],
  "missing_skills": ["Kafka", "Docker"],
  "ats_score": 70,
  "skills": ["Python", "FastAPI", "SQL"],
  "experience_level": "Junior",
  "lang": "tr"
}
```
