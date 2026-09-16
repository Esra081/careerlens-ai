import hashlib
import os
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any
import jwt

from app.core.config import settings

# PBKDF2 Parametreleri (NIST onaylı güvenli standart)
SALT_SIZE = 16
HASH_ITERATIONS = 100_000


def hash_password(password: str) -> str:
    """Kullanıcı şifresini PBKDF2-HMAC-SHA256 ile tuzlayıp (salt) güvenli hashler.
    
    Format: 'salt$hash' (hex kodlu)
    """
    salt = secrets.token_bytes(SALT_SIZE)
    hash_bytes = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        HASH_ITERATIONS,
    )
    return f"{salt.hex()}${hash_bytes.hex()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Düz metin şifreyi saklanan hash ile zamanlama saldırılarına (timing attack) dayanıklı karşılaştırır."""
    try:
        salt_hex, hash_hex = hashed_password.split("$")
        salt = bytes.fromhex(salt_hex)
        expected_hash = bytes.fromhex(hash_hex)
        actual_hash = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt,
            HASH_ITERATIONS,
        )
        return secrets.compare_digest(actual_hash, expected_hash)
    except Exception:
        return False


def create_access_token(subject: str | Any, expires_delta: timedelta | None = None) -> str:
    """Verilen konu (kullanıcı ID veya email) için JWT access token üretir."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    payload = {
        "sub": str(subject),
        "iat": now,
        "exp": expire,
    }
    encoded_jwt = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> dict | None:
    """JWT token'ı çözer ve payload'ı döner. Süresi dolmuşsa veya geçersizse None döner."""
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except jwt.PyJWTError:
        return None
