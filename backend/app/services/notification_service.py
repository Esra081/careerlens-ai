import firebase_admin
from firebase_admin import credentials, messaging
import os
from pathlib import Path

# Backend root directory
BASE_DIR = Path(__file__).resolve().parents[2]
FIREBASE_KEY_PATH = BASE_DIR / "firebase-adminsdk.json"

def init_firebase():
    """Firebase Admin SDK'yı başlatır."""
    if not firebase_admin._apps:
        if os.path.exists(FIREBASE_KEY_PATH):
            try:
                cred = credentials.Certificate(str(FIREBASE_KEY_PATH))
                firebase_admin.initialize_app(cred)
                print("[Firebase] Admin SDK başarıyla başlatıldı.")
            except Exception as e:
                print(f"[Firebase] Başlatma Hatası: {e}")
        else:
            print(f"[Firebase] HATA: Kimlik dosyası bulunamadı -> {FIREBASE_KEY_PATH}")

def send_job_match_notification(token: str, job_title: str, company: str, score: int) -> bool:
    """Belirli bir FCM token'a iş eşleşme bildirimi yollar."""
    if not firebase_admin._apps:
        print("[Firebase] Uyarı: Firebase başlatılmamış, bildirim gönderilemiyor.")
        return False
        
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=f"🚀 Yeni Eşleşme: {job_title}",
                body=f"{company} firmasında %{score} oranında eşleştiğin yeni bir ilan var!",
            ),
            data={
                "type": "job_match",
                "score": str(score),
            },
            token=token,
        )
        response = messaging.send(message)
        print(f"[Firebase] Bildirim başarıyla gönderildi: {response}")
        return True
    except Exception as e:
        print(f"[Firebase] Bildirim gönderme hatası: {e}")
        return False
