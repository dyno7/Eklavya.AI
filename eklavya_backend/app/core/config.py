"""
Application configuration using Pydantic Settings.
Loads from .env file and environment variables.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Database — Supabase PostgreSQL direct connection
    # Format: postgresql+asyncpg://user:pass@host:5432/dbname
    DATABASE_URL: str

    # Supabase project URL — for auth operations
    # Format: https://<project-ref>.supabase.co
    SUPABASE_URL: str

    # Supabase anon (public) key — for client-facing auth
    SUPABASE_ANON_KEY: str

    # Supabase JWT secret — for verifying auth tokens
    JWT_SECRET: str

    # Environment (development / staging / production)
    ENVIRONMENT: str = "development"


@lru_cache
def get_settings() -> Settings:
    """Cached settings singleton. Call this instead of constructing Settings directly."""
    return Settings()  # type: ignore[call-arg]
