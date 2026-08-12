"""
Eklavya.AI — Application-level in-process TTL cache.
Zero infrastructure required — pure Python, thread+async safe.
Falls back gracefully if cachetools not installed.
"""
import asyncio
import time
from typing import Any, Optional

try:
    from cachetools import TTLCache
    _CACHETOOLS = True
except ImportError:
    _CACHETOOLS = False

# Per-cache locks for async safety
_dashboard_lock = asyncio.Lock()
_gdi_lock = asyncio.Lock()
_analytics_lock = asyncio.Lock()

# ── Dashboard cache: 30s TTL, max 500 users in memory (~2MB) ──────────────────
_dashboard_cache: dict[str, tuple[Any, float]] = {}
_DASHBOARD_TTL = 30  # seconds

# ── GDI cache: 5 min TTL (GDI only changes on nightly sweep) ─────────────────
_gdi_cache: dict[str, tuple[Any, float]] = {}
_GDI_TTL = 300  # seconds

# ── Analytics cache: 60s TTL ──────────────────────────────────────────────────
_analytics_cache: dict[str, tuple[Any, float]] = {}
_ANALYTICS_TTL = 60  # seconds


async def _get(store: dict, key: str, lock: asyncio.Lock) -> Optional[Any]:
    """Get a value from a TTL store. Returns None if missing or expired."""
    async with lock:
        entry = store.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if time.monotonic() > expires_at:
            store.pop(key, None)
            return None
        return value


async def _set(store: dict, key: str, value: Any, ttl: float, lock: asyncio.Lock) -> None:
    """Set a value with TTL expiry. Evicts oldest entry if store exceeds 500 items."""
    async with lock:
        if len(store) >= 500:
            # Simple eviction: remove the first (oldest) key
            oldest = next(iter(store))
            store.pop(oldest, None)
        store[key] = (value, time.monotonic() + ttl)


async def _delete(store: dict, key: str, lock: asyncio.Lock) -> None:
    async with lock:
        store.pop(key, None)


# ── Public API ────────────────────────────────────────────────────────────────

class DashboardCache:
    @staticmethod
    async def get(user_id: str) -> Optional[Any]:
        return await _get(_dashboard_cache, user_id, _dashboard_lock)

    @staticmethod
    async def set(user_id: str, value: Any) -> None:
        await _set(_dashboard_cache, user_id, value, _DASHBOARD_TTL, _dashboard_lock)

    @staticmethod
    async def invalidate(user_id: str) -> None:
        """Call this on claim-task so next load is fresh."""
        await _delete(_dashboard_cache, user_id, _dashboard_lock)
        await _delete(_analytics_cache, user_id, _analytics_lock)  # also stale after a task claim


class AnalyticsCache:
    @staticmethod
    async def get(user_id: str) -> Optional[Any]:
        return await _get(_analytics_cache, user_id, _analytics_lock)

    @staticmethod
    async def set(user_id: str, value: Any) -> None:
        await _set(_analytics_cache, user_id, value, _ANALYTICS_TTL, _analytics_lock)


class GDICache:
    @staticmethod
    async def get(user_id: str) -> Optional[Any]:
        return await _get(_gdi_cache, user_id, _gdi_lock)

    @staticmethod
    async def set(user_id: str, value: Any) -> None:
        await _set(_gdi_cache, user_id, value, _GDI_TTL, _gdi_lock)

    @staticmethod
    async def invalidate(user_id: str) -> None:
        await _delete(_gdi_cache, user_id, _gdi_lock)
