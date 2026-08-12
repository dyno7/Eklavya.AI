"""
Shared HTTP client with connection pooling for external API calls.
Reduces connection overhead for JWKS, Gemini, link validation, etc.
"""
import httpx
from contextlib import asynccontextmanager
from app.core.config import get_settings

# Global client with connection pooling
_client: httpx.AsyncClient | None = None


def get_http_client() -> httpx.AsyncClient:
    """Get or create the shared HTTP client with connection pooling."""
    global _client
    if _client is None:
        settings = get_settings()
        limits = httpx.Limits(
            max_keepalive_connections=20,
            max_connections=100,
            keepalive_expiry=30.0,
        )
        timeout = httpx.Timeout(
            connect=5.0,
            read=30.0,
            write=10.0,
            pool=5.0,
        )
        _client = httpx.AsyncClient(
            limits=limits,
            timeout=timeout,
            headers={
                "User-Agent": "EklavyaBackend/1.0",
            },
        )
    return _client


async def close_http_client() -> None:
    """Close the shared HTTP client on shutdown."""
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None


@asynccontextmanager
async def http_client_context():
    """Context manager for HTTP client lifecycle (useful for testing)."""
    client = get_http_client()
    try:
        yield client
    finally:
        pass  # Client is managed globally