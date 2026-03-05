"""
JWT Authentication Middleware for LumenAI Backend.

Verifies Supabase-issued JWTs on every protected route.
Supports both HS256 (legacy) and ES256 (newer Supabase projects) algorithms.

Usage in routes:
    from app.middleware.auth import get_current_user
    @router.post("/endpoint")
    async def handler(user_id: str = Depends(get_current_user)):
        ...
"""
import os
import logging
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt  # PyJWT
from jwt import PyJWKClient

logger = logging.getLogger(__name__)

# Supabase JWT secret — used for HS256 tokens
JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "")

# Supabase JWKS URL — used for ES256 tokens
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
JWKS_URL = f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json" if SUPABASE_URL else ""

# Initialize JWKS client for ES256 key fetching
_jwks_client = None
if JWKS_URL:
    try:
        _jwks_client = PyJWKClient(JWKS_URL, cache_keys=True)
        logger.info(f"JWKS client initialized: {JWKS_URL}")
    except Exception as e:
        logger.warning(f"Failed to initialize JWKS client: {e}")

security_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
) -> str:
    """
    FastAPI dependency that extracts and validates the user_id from
    a Supabase-issued JWT in the Authorization header.

    Supports both HS256 (with JWT_SECRET) and ES256 (with JWKS) algorithms.
    Returns the user's UUID (sub claim) on success.
    Raises HTTP 401 on any failure.
    """
    token = credentials.credentials

    try:
        # Check the token header to determine algorithm
        header = jwt.get_unverified_header(token)
        alg = header.get("alg", "HS256")
        logger.info(f"JWT header: {header}")

        if alg == "ES256":
            # Use JWKS public key for ES256 verification
            if not _jwks_client:
                logger.error("ES256 token received but JWKS client is not configured!")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Server authentication not configured for ES256.",
                )
            signing_key = _jwks_client.get_signing_key_from_jwt(token)
            payload = jwt.decode(
                token,
                signing_key.key,
                algorithms=["ES256"],
                audience="authenticated",
            )
        else:
            # Use shared secret for HS256 verification
            if not JWT_SECRET:
                logger.error("SUPABASE_JWT_SECRET is not configured in .env!")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Server authentication not configured.",
                )
            payload = jwt.decode(
                token,
                JWT_SECRET,
                algorithms=["HS256"],
                audience="authenticated",
            )

        user_id: str = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing user identity.",
            )
        return user_id

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired.",
        )
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid JWT: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
        )
