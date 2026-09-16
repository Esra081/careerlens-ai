import unittest
import uuid
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.security import hash_password, verify_password, create_access_token, decode_access_token
from app.services import job_repository
from app.routers.auth_router import router as auth_router

test_app = FastAPI()
test_app.include_router(auth_router)
client = TestClient(test_app)



class TestAuthSystem(unittest.TestCase):

    def test_01_password_hashing(self):
        """Parola hashleme ve doğrulama testi."""
        pw = "stajyer_guclu_sifre_123"
        hashed = hash_password(pw)
        self.assertNotEqual(pw, hashed)
        self.assertTrue(verify_password(pw, hashed))
        self.assertFalse(verify_password("yanlis_sifre", hashed))

    def test_02_jwt_token(self):
        """JWT token üretme ve çözme testi."""
        subject = "test-user-id-123"
        token = create_access_token(subject)
        self.assertIsInstance(token, str)
        payload = decode_access_token(token)
        self.assertIsNotNone(payload)
        self.assertEqual(payload.get("sub"), subject)

    def test_03_auth_endpoints_lifecycle(self):
        """Kayıt, giriş ve /me endpoint yaşam döngüsü testi."""
        unique_email = f"stajyer_{uuid.uuid4().hex[:8]}@example.com"
        password = "secret_password_123"
        full_name = "Esra Kılıç"

        # 1. Register
        reg_res = client.post(
            "/api/v1/auth/register",
            json={"email": unique_email, "password": password, "full_name": full_name},
        )
        self.assertEqual(reg_res.status_code, 201)
        reg_data = reg_res.json()
        self.assertIn("access_token", reg_data)
        self.assertEqual(reg_data["user"]["email"], unique_email)
        token = reg_data["access_token"]

        # 2. Duplicate Register (Conflict 409)
        dup_res = client.post(
            "/api/v1/auth/register",
            json={"email": unique_email, "password": password, "full_name": full_name},
        )
        self.assertEqual(dup_res.status_code, 409)

        # 3. Login
        login_res = client.post(
            "/api/v1/auth/login",
            json={"email": unique_email, "password": password},
        )
        self.assertEqual(login_res.status_code, 200)
        login_data = login_res.json()
        self.assertIn("access_token", login_data)

        # 4. Login with Wrong Password (401)
        wrong_res = client.post(
            "/api/v1/auth/login",
            json={"email": unique_email, "password": "wrong_password"},
        )
        self.assertEqual(wrong_res.status_code, 401)

        # 5. Get Current User (/api/v1/auth/me)
        me_res = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        self.assertEqual(me_res.status_code, 200)
        me_data = me_res.json()
        self.assertEqual(me_data["email"], unique_email)
        self.assertEqual(me_data["full_name"], full_name)

        # 6. Update FCM Token
        fcm_res = client.post(
            "/api/v1/auth/fcm-token",
            headers={"Authorization": f"Bearer {token}"},
            json={"fcm_token": "mock_fcm_token_device_abc123"},
        )
        self.assertEqual(fcm_res.status_code, 200)


if __name__ == "__main__":
    unittest.main()
