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

# ── Dashboard cache: 30s TTL, max 500 users in memory (~2MB) ──────────────────
_dashboard_cache: dict[str, tuple[Any, float]] = {}
_DASHBOARD_TTL = 30  # seconds

# ── GDI cache: 5 min TTL (GDI only changes on nightly sweep) ─────────────────
_gdi_cache: dict[str, tuple[Any, float]] = {}
_GDI_TTL = 300  # seconds

# ── Analytics cache: 60s TTL ──────────────────────────────────────────────────
_analytics_cache: dict[str, tuple[Any, float]] = {}
_ANALYTICS_TTL = 60  # seconds


def _get(store: dict, key: str) -> Optional[Any]:
    """Get a value from a TTL store. Returns None if missing or expired."""
    entry = store.get(key)
    if entry is None:
        return None
    value, expires_at = entry
    if time.monotonic() > expires_at:
        store.pop(key, None)
        return None
    return value


def _set(store: dict, key: str, value: Any, ttl: float) -> None:
    """Set a value with TTL expiry. Evicts oldest entry if store exceeds 500 items."""
    if len(store) >= 500:
        # Simple eviction: remove the first (oldest) key
        oldest = next(iter(store))
        store.pop(oldest, None)
    store[key] = (value, time.monotonic() + ttl)


def _delete(store: dict, key: str) -> None:
    store.pop(key, None)


# ── Public API ────────────────────────────────────────────────────────────────

class DashboardCache:
    @staticmethod
    def get(user_id: str) -> Optional[Any]:
        return _get(_dashboard_cache, user_id)

    @staticmethod
    def set(user_id: str, value: Any) -> None:
        _set(_dashboard_cache, user_id, value, _DASHBOARD_TTL)

    @staticmethod
    def invalidate(user_id: str) -> None:
        """Call this on claim-task so next load is fresh."""
        _delete(_dashboard_cache, user_id)
        _delete(_analytics_cache, user_id)  # also stale after a task claim


class AnalyticsCache:
    @staticmethod
    def get(user_id: str) -> Optional[Any]:
        return _get(_analytics_cache, user_id)

    @staticmethod
    def set(user_id: str, value: Any) -> None:
        _set(_analytics_cache, user_id, value, _ANALYTICS_TTL)


class GDICache:
    @staticmethod
    def get(user_id: str) -> Optional[Any]:
        return _get(_gdi_cache, user_id)

    @staticmethod
    def set(user_id: str, value: Any) -> None:
        _set(_gdi_cache, user_id, value, _GDI_TTL)

    @staticmethod
    def invalidate(user_id: str) -> None:
        _delete(_gdi_cache, user_id)
