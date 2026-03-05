"""
JWT Authentication Middleware for LumenAI Backend.

Verifies Supabase-issued JWTs on every protected route.
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

logger = logging.getLogger(__name__)

# Supabase JWT secret — MUST be set in .env
JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "")
JWT_ALGORITHM = "HS256"

security_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
) -> str:
    """
    FastAPI dependency that extracts and validates the user_id from
    a Supabase-issued JWT in the Authorization header.

    Returns the user's UUID (sub claim) on success.
    Raises HTTP 401 on any failure.
    """
    token = credentials.credentials

    if not JWT_SECRET:
        logger.error("SUPABASE_JWT_SECRET is not configured in .env!")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Server authentication not configured.",
        )

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
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
