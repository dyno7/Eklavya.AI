from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.presentation.goals import router as goals_router
from app.presentation.tasks import router as tasks_router
from app.presentation.users import router as users_router
from app.presentation.chat import router as chat_router
from app.presentation.dashboard import router as dashboard_router
from app.presentation.notifications import router as notifications_router
from app.presentation.analytics import router as analytics_router

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.core.gdi_service import GdiService
import logging

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown hooks."""
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
        logger.error(f"Scheduler failed to start: {e}")

    yield

    scheduler.shutdown()
app = FastAPI(
    title="Eklavya.AI Core API",
    description="Backend for the Eklavya.AI gamified learning and execution platform.",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS — wide open for development, lock down in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API routers
app.include_router(goals_router)
app.include_router(tasks_router)
app.include_router(users_router)
app.include_router(chat_router)
app.include_router(dashboard_router)
app.include_router(notifications_router)
app.include_router(analytics_router)


@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Eklavya API is running"}
