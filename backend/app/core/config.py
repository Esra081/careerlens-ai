import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Merkezi uygulama konfigürasyonu."""
    
    # Uygulama Bilgileri
    PROJECT_NAME: str = "CareerLens AI"
    VERSION: str = "0.3.0"
    API_V1_STR: str = "/api/v1"

    # Güvenlik & JWT Ayarları
    # Production ortamında güçlü bir secret key ortam değişkeni olarak verilmelidir
    JWT_SECRET_KEY: str = "careerlens_super_secret_jwt_key_staj_2026_change_in_prod"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 gün

    # Dosya Yükleme Sınırları
    MAX_FILE_SIZE_BYTES: int = 10 * 1024 * 1024  # 10 MB

    # Dış API Anahtarları
    GEMINI_API_KEY: str = ""
    ADZUNA_APP_ID: str = ""
    ADZUNA_APP_KEY: str = ""
    ADZUNA_COUNTRY: str = "tr"
    CAREERJET_API_KEY: str = ""
    JOOBLE_API_KEY: str = ""

    # CORS Ayarları
    CORS_ORIGINS: list[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=(
            Path(__file__).resolve().parents[2] / ".env",
            Path(__file__).resolve().parents[3] / ".env",
        ),
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
