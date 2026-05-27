import logging

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.presentation.goals import router as goals_router
from app.presentation.tasks import router as tasks_router
from app.presentation.users import router as users_router
from app.presentation.chat import router as chat_router
from app.presentation.dashboard import router as dashboard_router
from app.presentation.notifications import router as notifications_router
from app.presentation.analytics import router as analytics_router
from app.presentation.coach import router as coach_router

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.core.gdi_service import GdiService
from app.core.config import get_settings

logger = logging.getLogger(__name__)

# ─── Simple in-memory rate limiter ───────────────────────────
import time
from collections import defaultdict

_rate_limit_store: dict[str, list[float]] = defaultdict(list)
_RATE_LIMIT_WINDOW = 60  # seconds
_RATE_LIMIT_MAX = 30     # max requests per window per user


def _is_rate_limited(key: str) -> bool:
    """Check if a key has exceeded the rate limit."""
    now = time.monotonic()
    window = _rate_limit_store[key]
    # Prune old entries
    _rate_limit_store[key] = [t for t in window if now - t < _RATE_LIMIT_WINDOW]
    if len(_rate_limit_store[key]) >= _RATE_LIMIT_MAX:
        return True
    _rate_limit_store[key].append(now)
    return False


scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown hooks."""
    # Configure structured logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )

    try:
        # Add midnight GDI sweep job
        scheduler.add_job(
            GdiService.run_midnight_decay_sweep,
            'cron',
            hour=0,
            minute=0,
            id="gdi_nightly_sweep",
            replace_existing=True
        )
        scheduler.start()
        logger.info("APScheduler started: GDI Sweep scheduled.")
    except Exception as e:
        logger.error("Scheduler failed to start: %s", e)

    yield

    scheduler.shutdown()

app = FastAPI(
    title="Eklavya.AI Core API",
    description="Backend for the Eklavya.AI gamified learning and execution platform.",
    version="1.0.0",
    lifespan=lifespan,
    # Disable docs in production
    docs_url="/docs" if get_settings().ENVIRONMENT == "development" else None,
    redoc_url="/redoc" if get_settings().ENVIRONMENT == "development" else None,
)

# ─── CORS — environment-aware ───────────────────────────────
# NOTE: allow_origins=["*"] + allow_credentials=True is invalid per spec; browsers
# reject preflight responses. We use Bearer tokens (Authorization header), not
# cookies — so allow_credentials=False is safe and lets wildcards actually work
# in development. In production, allow_credentials remains False with explicit origins.
settings = get_settings()
if settings.ENVIRONMENT == "development":
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=".*",
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["X-Response-Time"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "https://eklavya.ai",
            "https://www.eklavya.ai",
            "https://api.eklavya.ai",
        ],
        allow_credentials=False,
        allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type"],
    )


# ─── Rate limiting middleware ────────────────────────────────
_RATE_LIMITED_PREFIXES = ("/api/chat/send", "/api/v1/dashboard/claim-task")


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    """Simple per-user rate limiter for sensitive endpoints.

    Skips CORS preflight (OPTIONS) — those must always pass through to the
    CORS middleware so the browser gets a valid preflight response.
    """
    if request.method == "OPTIONS":
        return await call_next(request)
    if any(request.url.path.startswith(p) for p in _RATE_LIMITED_PREFIXES):
        client_ip = request.client.host if request.client else "unknown"
        rate_key = f"{client_ip}:{request.url.path}"
        if _is_rate_limited(rate_key):
            return JSONResponse(
                status_code=429,
                content={"detail": "Too many requests. Please slow down."},
            )
    return await call_next(request)


@app.middleware("http")
async def timing_middleware(request: Request, call_next):
    """Adds X-Response-Time header (ms) to every response for latency visibility."""
    start = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start) * 1000
    response.headers["X-Response-Time"] = f"{elapsed_ms:.1f}ms"
    if elapsed_ms > 500:
        logger.warning("SLOW REQUEST: %s %s took %.0fms",
                       request.method, request.url.path, elapsed_ms)
    return response


# Register API routers
app.include_router(goals_router)
app.include_router(tasks_router)
app.include_router(users_router)
app.include_router(chat_router)
app.include_router(dashboard_router)
app.include_router(notifications_router)
app.include_router(analytics_router)
app.include_router(coach_router)


@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Eklavya API is running"}

