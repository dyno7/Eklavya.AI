"""
Async SQLAlchemy engine, session factory, and declarative base.
Uses asyncpg driver to connect directly to Supabase PostgreSQL.

Engine and session are initialized lazily to avoid config validation
errors during import when .env is not present (e.g., during testing).
"""

from collections.abc import AsyncGenerator
from typing import Optional

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""
    pass


# Lazy-initialized engine and session factory
_engine: Optional[AsyncEngine] = None
_async_session: Optional[async_sessionmaker[AsyncSession]] = None


def get_engine() -> AsyncEngine:
    """Get or create the async engine (lazy init)."""
    global _engine
    if _engine is None:
        from app.core.config import get_settings
        settings = get_settings()
        
        # Production-tuned pool settings
        is_prod = settings.ENVIRONMENT == "production"
        pool_size = 20 if is_prod else 10
        max_overflow = 30 if is_prod else 20
        
        _engine = create_async_engine(
            settings.DATABASE_URL,
            echo=settings.ENVIRONMENT == "development",
            pool_pre_ping=True,
            pool_size=pool_size,
            max_overflow=max_overflow,
            pool_timeout=10,       # Reduced from 30s - fail fast under contention
            pool_recycle=1800,
            connect_args={
                "ssl": "require",
                "statement_cache_size": 0,
                "server_settings": {
                    "application_name": "eklavya-backend",
                    "jit": "off",  # Disable JIT for lower latency on small queries
                },
            },
        )
    return _engine


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    """Get or create the session factory (lazy init)."""
    global _async_session
    if _async_session is None:
        _async_session = async_sessionmaker(
            get_engine(),
            class_=AsyncSession,
            expire_on_commit=False,
        )
    return _async_session


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency that yields an async database session."""
    session_factory = get_session_factory()
    async with session_factory() as session:
        try:
            yield session
        finally:
            await session.close()
