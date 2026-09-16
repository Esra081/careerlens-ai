from pydantic import BaseModel, EmailStr, Field


class UserRegisterRequest(BaseModel):
    email: str = Field(..., description="Kullanıcı e-posta adresi")
    password: str = Field(..., min_length=6, description="En az 6 karakterli şifre")
    full_name: str = Field(..., min_length=2, description="Kullanıcı adı ve soyadı")


class UserLoginRequest(BaseModel):
    email: str = Field(..., description="Kullanıcı e-posta adresi")
    password: str = Field(..., description="Kullanıcı şifresi")


class UserResponse(BaseModel):
    id: str
    email: str
    full_name: str
    fcm_token: str | None = None
    created_at: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class UpdateFcmTokenRequest(BaseModel):
    fcm_token: str = Field(..., min_length=1, description="Firebase Cloud Messaging cihaz token'ı")
