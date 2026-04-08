"""
Auth dependency — validates Supabase JWT tokens and extracts user ID.

Every authenticated endpoint injects this via:
    current_user_id: uuid.UUID = Depends(get_current_user_id)
"""

import uuid
import logging
import time

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel

from app.core.config import get_settings

# HTTPBearer extracts "Bearer <token>" from the Authorization header
_bearer_scheme = HTTPBearer()
logger = logging.getLogger(__name__)
_JWKS_CACHE: dict[str, object] = {"expires_at": 0.0, "keys": []}


class CurrentUser(BaseModel):
    id: uuid.UUID
    display_name: str


async def _get_supabase_jwks() -> list[dict]:
    """Fetch and cache Supabase JWKS keys for RS/ES token verification."""
    now = time.monotonic()
    cached_keys = _JWKS_CACHE.get("keys")
    expires_at = float(_JWKS_CACHE.get("expires_at", 0.0))
    if isinstance(cached_keys, list) and cached_keys and now < expires_at:
        return cached_keys

    settings = get_settings()
    jwks_url = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json"

    async with httpx.AsyncClient(timeout=5.0) as client:
        response = await client.get(jwks_url)
        response.raise_for_status()
        payload = response.json()

    keys = payload.get("keys", []) if isinstance(payload, dict) else []
    if not isinstance(keys, list):
        raise JWTError("Invalid JWKS payload from Supabase")

    _JWKS_CACHE["keys"] = keys
    _JWKS_CACHE["expires_at"] = now + 300.0
    return keys


async def _resolve_verification_key(token: str, alg: str):
    """Resolve key material for JWT verification based on algorithm and header."""
    settings = get_settings()

    if alg == "HS256":
        return settings.JWT_SECRET

    if alg in ("RS256", "ES256"):
        # If explicitly provided, prefer configured PEM public key.
        if settings.SUPABASE_JWT_PUBLIC_KEY:
            return settings.SUPABASE_JWT_PUBLIC_KEY

        # Otherwise resolve from Supabase JWKS by key id.
        header = jwt.get_unverified_header(token)
        kid = (header or {}).get("kid")
        if not kid:
            raise JWTError(f"{alg} token missing kid header")

        jwks = await _get_supabase_jwks()
        for key in jwks:
            if isinstance(key, dict) and key.get("kid") == kid:
                return key

        raise JWTError(f"No JWKS key found for kid={kid}")

    raise JWTError(f"Unsupported JWT alg: {alg}")


async def _decode_supabase_token(token: str):
    """Decode Supabase JWT with algorithm-aware verification."""
    header = jwt.get_unverified_header(token)
    alg = (header or {}).get("alg", "")
    key = await _resolve_verification_key(token, alg)
    return jwt.decode(
        token,
        key,
        algorithms=[alg],
        audience="authenticated",
    )


def _extract_display_name(payload: dict) -> str:
    user_metadata = payload.get("user_metadata") or {}
    app_metadata = payload.get("app_metadata") or {}

    if isinstance(user_metadata, dict):
        for key in ("display_name", "full_name", "name"):
            value = user_metadata.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()

    if isinstance(app_metadata, dict):
        value = app_metadata.get("display_name")
        if isinstance(value, str) and value.strip():
            return value.strip()

    for key in ("name", "preferred_username"):
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()

    email = payload.get("email")
    if isinstance(email, str) and "@" in email:
        return email.split("@", 1)[0]

    return "Learner"


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme),
) -> CurrentUser:
    """Decode Supabase JWT and return normalized user context."""
    settings = get_settings()
    token = credentials.credentials

    try:
        payload = await _decode_supabase_token(token)
    except JWTError as exc:
        if settings.ENVIRONMENT == "development":
            logger.warning("JWT verification failed in development (%s). Falling back to unverified claims.", exc)
            payload = jwt.get_unverified_claims(token)
        else:
            logger.error("JWT decode failed: %s", exc)
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
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        logger.error("Invalid user_id format: %s", user_id)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid user_id format: {user_id}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return CurrentUser(id=user_uuid, display_name=_extract_display_name(payload))


async def get_current_user_id(
    current_user: CurrentUser = Depends(get_current_user),
) -> uuid.UUID:
    """Backward-compatible dependency that returns only user UUID."""
    return current_user.id
