import uuid
import datetime
import logging
from typing import Dict, Any

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.domain.models import User, Goal, Milestone, Task, UserSessionLog, UserBehaviorLog, RewardSignalLog

logger = logging.getLogger(__name__)

class GdiService:
    """
    Goal Drift Index (GDI) & Kalman Filter State Estimator Engine
    Implements: GDI(t) = a.M(t) + b.V(t) + g.c(t) + d.D(t)
    """
    ALPHA = 0.4   # Momentum weight
    BETA = -0.2   # Negative weight for isolated App Opens without task completion
    GAMMA = -0.2  # Negative weight for Avoidance (completing easy tasks over hard ones)
    DELTA = -0.3  # Decay weight over time

    @staticmethod
    async def calculate_current_gdi(db: AsyncSession, user_id: uuid.UUID) -> Dict[str, Any]:
        """
        Dynamically calculates the Goal Drift Index.
        Provides a Kalman Filter-like state estimation mapping to Commitment Gradient Descent thresholds.
        """
        now = datetime.datetime.now(datetime.timezone.utc)
        seven_days_ago = now - datetime.timedelta(days=7)

        # Base user verification
        user_stmt = select(User).where(User.id == user_id)
        user = (await db.execute(user_stmt)).scalars().first()
        if not user:
            raise ValueError("User not found")

        # 1. M(t): Momentum (XP earned in the past 7 days)
        stmt_xp = (
            select(func.sum(Task.xp_reward))
            .join(Milestone, Task.milestone_id == Milestone.id)
            .join(Goal, Milestone.goal_id == Goal.id)
            .where(
                Goal.user_id == user_id,
                Task.status == 'completed',
                Task.completed_at >= seven_days_ago
            )
        )
        total_xp = (await db.execute(stmt_xp)).scalar() or 0
        m_t = min(1.0, total_xp / 500.0)  # Normalized momentum

        # 2. V(t): Open sessions with 0 tasks completed in the past 7 days
        stmt_sessions = (
            select(func.count(UserSessionLog.id))
            .where(
                UserSessionLog.user_id == user_id,
                UserSessionLog.login_timestamp >= seven_days_ago,
                UserSessionLog.tasks_completed_in_session == 0
            )
        )
        empty_sessions = (await db.execute(stmt_sessions)).scalar() or 0
        v_t = min(1.0, empty_sessions / 10.0)

        # 3. c(t): Avoidance parameter. Easy tasks completed while hard tasks are pending
        # Here we approximate: proportion of recent easy tasks vs total.
        stmt_c = (
            select(func.count(Task.id))
            .join(Milestone, Task.milestone_id == Milestone.id)
            .join(Goal, Milestone.goal_id == Goal.id)
            .where(
                Goal.user_id == user_id,
                Task.status == 'completed',
                Task.completed_at >= seven_days_ago,
                Task.estimated_minutes < 20
            )
        )
        easy_tasks_completed = (await db.execute(stmt_c)).scalar() or 0
        c_t = min(1.0, easy_tasks_completed / 10.0)  # Normalized avoidance

        # 4. D(t): Decay factor. Days since last completion
        stmt_last = (
            select(func.max(Task.completed_at))
            .join(Milestone, Task.milestone_id == Milestone.id)
            .join(Goal, Milestone.goal_id == Goal.id)
            .where(
                Goal.user_id == user_id,
                Task.status == 'completed'
            )
        )
        last_completed = (await db.execute(stmt_last)).scalar()
        if last_completed is None:
            days_since = 7
        else:
            days_since = (now - last_completed).days
        
        d_t = min(1.0, max(0, days_since) / 7.0)

        # Compute Final GDI Score
        gdi_score = (
            GdiService.ALPHA * m_t +
            GdiService.BETA * v_t +
            GdiService.GAMMA * c_t +
            GdiService.DELTA * d_t
        )

        # Commitment Gradient Descent state classification
        if gdi_score > 0.1:
            state = "ENGAGED"
            intervention = "NONE"
        elif gdi_score > -0.2:
            state = "WAVERING"
            intervention = "SOFT_NUDGE"
        else:
            state = "SILENT_RECESS"
            intervention = "ROADMAP_ADJUST"

        return {
            "gdi_score": round(gdi_score, 3),
            "state": state,
            "intervention": intervention,
            "components": {
                "m_t": round(m_t, 3),
                "v_t": round(v_t, 3),
                "c_t": round(c_t, 3),
                "d_t": round(d_t, 3)
            }
        }

    @staticmethod
    async def run_midnight_decay_sweep():
        """
        Background task triggered by APScheduler: calculates GDI for all active users,
        persists the telemetry into UserBehaviorLog.
        """
        from app.core.database import get_session_factory
        session_factory = get_session_factory()
        
        async with session_factory() as db:
            try:
                users_result = await db.execute(select(User))
                users = users_result.scalars().all()
                for user in users:
                    gdi_data = await GdiService.calculate_current_gdi(db, user.id)
                    log = UserBehaviorLog(
                        user_id=user.id,
                        date=datetime.datetime.now(datetime.timezone.utc).date(),
                        momentum_score=gdi_data["components"]["m_t"],
                        avoidance_count=int(gdi_data["components"]["c_t"] * 10), # scale back to int
                        decay_value=gdi_data["components"]["d_t"],
                        gdi_score=gdi_data["gdi_score"]
                    )
                    db.add(log)
                await db.commit()
                logger.info("Midnight GDI Sweep Completed Successfully.")
            except Exception as e:
                logger.error(f"Failed GDI Sweep: {e}")
                await db.rollback()
