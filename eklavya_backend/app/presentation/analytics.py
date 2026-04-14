"""
Analytics API router — real usage metrics for the Flutter analytics tab.

Endpoints:
- GET /api/v1/analytics/summary — Weekly XP, completion rate, active days
"""

from collections import defaultdict
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser, get_current_user
from app.core.database import get_db
from app.core import repositories as repo

router = APIRouter(prefix="/api/v1/analytics", tags=["Analytics"])


# ─── Response schemas ───────────────────────────────

class AnalyticsSummary(BaseModel):
    daily_xp: list[int]          # 7 elements, oldest→newest (M,T,W,T,F,S,S → past 7 days)
    completion_rate: float       # 0.0–1.0
    active_days_last_30: int     # distinct days with ≥1 completion
    total_tasks: int
    completed_tasks: int


# ─── Endpoints ──────────────────────────────────────

@router.get("/summary", response_model=AnalyticsSummary)
async def get_analytics_summary(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Return real usage analytics for the authenticated user."""
    user_id = current_user.id
    now = datetime.now(timezone.utc)

    # 1. Get task completions for the last 30 days
    completions = await repo.get_task_completions_for_user(db, user_id, days=30)

    # 2. Build daily XP for last 7 days
    daily_xp: dict[str, int] = defaultdict(int)
    active_dates: set[str] = set()

    for task in completions:
        if task.completed_at is None:
            continue
        day_key = task.completed_at.strftime("%Y-%m-%d")
        daily_xp[day_key] += task.xp_reward
        active_dates.add(day_key)

    # Build 7-day array (oldest first)
    weekly = []
    for i in range(6, -1, -1):
        day = (now - timedelta(days=i)).strftime("%Y-%m-%d")
        weekly.append(daily_xp.get(day, 0))

    # 3. Task counts
    total_tasks, completed_tasks = await repo.get_all_tasks_for_user(db, user_id)
    completion_rate = completed_tasks / total_tasks if total_tasks > 0 else 0.0

    return AnalyticsSummary(
        daily_xp=weekly,
        completion_rate=round(completion_rate, 3),
        active_days_last_30=len(active_dates),
        total_tasks=total_tasks,
        completed_tasks=completed_tasks,
    )

@router.post("/session_start")
async def log_session_start(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Telemetry endpoint for Flutter app foregrounding."""
    from app.domain.models import UserSessionLog
    
    log = UserSessionLog(user_id=current_user.id, login_timestamp=datetime.now(timezone.utc))
    db.add(log)
    await db.commit()
    return {"status": "ok"}
