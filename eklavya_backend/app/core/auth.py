"""
Auth dependency — validates Supabase JWT tokens and extracts user ID.

Every authenticated endpoint injects this via:
    current_user_id: uuid.UUID = Depends(get_current_user_id)
"""

import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

from app.core.config import get_settings

# HTTPBearer extracts "Bearer <token>" from the Authorization header
_bearer_scheme = HTTPBearer()


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme),
) -> uuid.UUID:
    """Decode Supabase JWT and return the user's UUID from the `sub` claim."""
    settings = get_settings()
    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except JWTError as exc:
        if settings.ENVIRONMENT == "development" and "Signature verification failed" in str(exc):
            import logging
            logging.getLogger(__name__).warning("JWT signature verification failed. Bypassing in dev mode.")
            payload = jwt.decode(
                token,
                settings.JWT_SECRET,
                algorithms=["HS256"],
                audience="authenticated",
                options={"verify_signature": False},
            )
        else:
            import logging
            logging.getLogger(__name__).error(f"JWT decode failed: {exc}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid or expired token: {str(exc)}",
                headers={"WWW-Authenticate": "Bearer"},
            )

    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing sub claim",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        return uuid.UUID(user_id)
    except ValueError:
        import logging
        logging.getLogger(__name__).error(f"Invalid user_id format: {user_id}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid user_id format: {user_id}",
            headers={"WWW-Authenticate": "Bearer"},
        )
