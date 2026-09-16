import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.services import job_repository
from app.core.security import hash_password

def seed():
    job_repository.initialize()

    users_to_seed = [
        {
            "email": "demo@careerlens.ai",
            "password": "password123",
            "full_name": "Demo Kullanıcı",
        },
        {
            "email": "esra@careerlens.ai",
            "password": "password123",
            "full_name": "Esra Kılıç",
        },
    ]

    print("--- Seed Kullanıcıları Kontrol Ediliyor ---")
    for u in users_to_seed:
        existing = job_repository.get_user_by_email(u["email"])
        if existing:
            print(f"[MEVCUT] {u['email']} zaten kayıtlı.")
        else:
            hashed = hash_password(u["password"])
            job_repository.create_user(
                email=u["email"],
                hashed_password=hashed,
                full_name=u["full_name"],
            )
            print(f"[EKLENDİ] {u['email']} başarıyla oluşturuldu. (Şifre: {u['password']})")

if __name__ == "__main__":
    seed()
