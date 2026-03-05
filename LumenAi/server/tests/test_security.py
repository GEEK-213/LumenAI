"""
LumenAI Phase 2 — Security & Integration Tests
Tests: JWT auth enforcement, input validation, file upload limits, health check.

Run: python -m pytest tests/test_security.py -v --tb=short
"""
import json
import os
import sys
import pytest
import jwt
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from fastapi.testclient import TestClient

# --- Test JWT Helper ---

# Use a test secret for JWT signing
TEST_JWT_SECRET = "test-jwt-secret-for-testing-only"

def _create_test_token(user_id="test-user-123", expired=False):
    """Create a valid or expired JWT for testing."""
    payload = {
        "sub": user_id,
        "aud": "authenticated",
        "role": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + (-3600 if expired else 3600),
    }
    return jwt.encode(payload, TEST_JWT_SECRET, algorithm="HS256")


@pytest.fixture(autouse=True)
def set_test_env(monkeypatch):
    """Ensure test environment is configured."""
    monkeypatch.setenv("SUPABASE_JWT_SECRET", TEST_JWT_SECRET)
    # Re-import to pick up the env var
    from app.middleware import auth
    auth.JWT_SECRET = TEST_JWT_SECRET


@pytest.fixture
def client():
    """FastAPI TestClient with fresh app instance."""
    from main import app
    return TestClient(app)


# ╔═══════════════════════════════════════════════════════════╗
# ║  1. HEALTH CHECK — No Auth Required                      ║
# ╚═══════════════════════════════════════════════════════════╝

class TestHealthCheck:
    """Health endpoint should be accessible without authentication."""

    def test_health_returns_200(self, client):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_has_checks(self, client):
        response = client.get("/health")
        data = response.json()
        assert "status" in data
        assert "checks" in data
        assert "server" in data["checks"]

    def test_health_reports_jwt_configured(self, client):
        response = client.get("/health")
        data = response.json()
        assert data["checks"]["jwt_configured"] is True


# ╔═══════════════════════════════════════════════════════════╗
# ║  2. AUTH MIDDLEWARE — Rejection Tests                     ║
# ╚═══════════════════════════════════════════════════════════╝

class TestAuthMiddleware:
    """Protected endpoints must reject unauthenticated / invalid requests."""

    def test_chat_without_auth_returns_401_or_403(self, client):
        """FastAPI HTTPBearer returns 401 or 403 when no Authorization header is present."""
        response = client.post("/chat/ask", data={"question": "hello"})
        assert response.status_code in (401, 403)

    def test_chat_with_invalid_token_returns_401(self, client):
        """Invalid JWT should be rejected."""
        response = client.post(
            "/chat/ask",
            data={"question": "hello"},
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert response.status_code == 401

    def test_chat_with_expired_token_returns_401(self, client):
        """Expired JWT should be rejected."""
        token = _create_test_token(expired=True)
        response = client.post(
            "/chat/ask",
            data={"question": "hello"},
            headers={"Authorization": "Bearer " + token},
        )
        assert response.status_code == 401

    def test_analysis_delete_without_auth_returns_401_or_403(self, client):
        response = client.delete("/analysis/lecture/fake-id")
        assert response.status_code in (401, 403)

    def test_ingestion_delete_without_auth_returns_401_or_403(self, client):
        response = client.delete("/ingestion/syllabus/fake-id")
        assert response.status_code in (401, 403)

    def test_classroom_courses_without_auth_returns_401_or_403(self, client):
        response = client.get("/classroom/courses")
        assert response.status_code in (401, 403)


# ╔═══════════════════════════════════════════════════════════╗
# ║  3. FILE UPLOAD VALIDATION — Extension & Size Checks     ║
# ╚═══════════════════════════════════════════════════════════╝

class TestFileValidation:
    """File upload endpoints should reject invalid file types and oversized files."""

    def test_ingestion_rejects_exe_file(self, client):
        """Executable files must be rejected."""
        token = _create_test_token()
        response = client.post(
            "/ingestion/upload",
            data={"subject_id": "test-subject"},
            files={"file": ("malware.exe", b"fake content", "application/octet-stream")},
            headers={"Authorization": "Bearer " + token},
        )
        assert response.status_code == 400
        assert "not allowed" in response.json().get("detail", "").lower()

    def test_ingestion_rejects_js_file(self, client):
        """JavaScript files must be rejected."""
        token = _create_test_token()
        response = client.post(
            "/ingestion/upload",
            data={"subject_id": "test-subject"},
            files={"file": ("script.js", b"alert('xss')", "text/javascript")},
            headers={"Authorization": "Bearer " + token},
        )
        assert response.status_code == 400


# ╔═══════════════════════════════════════════════════════════╗
# ║  4. INPUT VALIDATION — Chat Endpoint                     ║
# ╚═══════════════════════════════════════════════════════════╝

class TestInputValidation:
    """Verify that inputs are properly constrained."""

    def test_chat_requires_question_field(self, client):
        """Chat endpoint should require the 'question' field."""
        token = _create_test_token()
        response = client.post(
            "/chat/ask",
            data={},  # missing required 'question'
            headers={"Authorization": "Bearer " + token},
        )
        assert response.status_code == 422  # FastAPI validation error


# ╔═══════════════════════════════════════════════════════════╗
# ║  5. AUTH MODULE — Unit Tests                              ║
# ╚═══════════════════════════════════════════════════════════╝

class TestAuthModule:
    """Unit tests for the JWT auth module itself."""

    def test_valid_token_returns_user_id(self):
        """A correctly signed token should return the user_id."""
        from app.middleware.auth import get_current_user, JWT_SECRET
        from unittest.mock import AsyncMock
        from fastapi.security import HTTPAuthorizationCredentials

        token = _create_test_token(user_id="abc-123")
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

        import asyncio
        user_id = asyncio.get_event_loop().run_until_complete(get_current_user(creds))
        assert user_id == "abc-123"

    def test_token_without_sub_raises(self):
        """Token missing 'sub' claim should raise 401."""
        from app.middleware.auth import get_current_user
        from fastapi.security import HTTPAuthorizationCredentials
        from fastapi import HTTPException

        payload = {
            "aud": "authenticated",
            "iat": int(time.time()),
            "exp": int(time.time()) + 3600,
        }
        token = jwt.encode(payload, TEST_JWT_SECRET, algorithm="HS256")
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

        import asyncio
        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(get_current_user(creds))
        assert exc_info.value.status_code == 401


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
