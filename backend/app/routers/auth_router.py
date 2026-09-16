from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.models.auth_models import (
    UserRegisterRequest,
    UserLoginRequest,
    UserResponse,
    TokenResponse,
    UpdateFcmTokenRequest,
)
from app.core.security import hash_password, verify_password, create_access_token, decode_access_token
from app.services import job_repository

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])

security_scheme = HTTPBearer(auto_error=True)


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security_scheme)) -> dict:
    """Bearer token'dan geçerli oturum açmış kullanıcıyı doğrular."""
    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz veya süresi dolmuş oturum anahtarı (token).",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload["sub"]
    user = job_repository.get_user_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Kullanıcı bulunamadı veya oturum geçersiz.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(request: UserRegisterRequest):
    """Yeni kullanıcı kaydı oluşturur ve otomatik oturum token'ı döner."""
    clean_email = request.email.strip().lower()
    existing_user = job_repository.get_user_by_email(clean_email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bu e-posta adresiyle kayıtlı bir hesap zaten var.",
        )

    hashed_pw = hash_password(request.password)
    user = job_repository.create_user(
        email=clean_email,
        hashed_password=hashed_pw,
        full_name=request.full_name,
    )

    access_token = create_access_token(subject=user["id"])
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(
            id=user["id"],
            email=user["email"],
            full_name=user["full_name"],
            fcm_token=None,
            created_at=user["created_at"],
        ),
    )


@router.post("/login", response_model=TokenResponse)
def login(request: UserLoginRequest):
    """Kullanıcı e-posta ve şifresiyle giriş yapar, JWT token üretir."""
    clean_email = request.email.strip().lower()
    user = job_repository.get_user_by_email(clean_email)
    if not user or not verify_password(request.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-posta veya şifre hatalı.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(subject=user["id"])
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(
            id=user["id"],
            email=user["email"],
            full_name=user["full_name"],
            fcm_token=user.get("fcm_token"),
            created_at=user["created_at"],
        ),
    )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: dict = Depends(get_current_user)):
    """Giriş yapmış olan kullanıcının profil bilgilerini döner."""
    return UserResponse(
        id=current_user["id"],
        email=current_user["email"],
        full_name=current_user["full_name"],
        fcm_token=current_user.get("fcm_token"),
        created_at=current_user["created_at"],
    )


@router.post("/fcm-token")
def update_fcm_token(request: UpdateFcmTokenRequest, current_user: dict = Depends(get_current_user)):
    """Oturum açmış kullanıcının bildirim token'ını günceller."""
    success = job_repository.update_user_fcm_token(current_user["id"], request.fcm_token)
    if not success:
        raise HTTPException(status_code=500, detail="Token güncellenemedi.")
    return {"status": "success", "message": "Bildirim token'ı başarıyla güncellendi."}
