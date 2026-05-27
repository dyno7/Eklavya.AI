"""
Eklavya.AI — Adaptive Personalized GDI
=======================================
Replaces the static GDI formula weights with per-user adaptive weights
stored in the DB. Falls back to global defaults for new users (cold start).

Formula: GDI(t) = alpha*M(t) + beta*V(t) + gamma*c(t) + delta*D(t)

Weights adapt using exponential smoothing when we observe outcome signals:
  - 'milestone_completed': user was predicted low but succeeded → boost alpha
  - 'churned': user was predicted high but went silent → penalise momentum weight

Each user's weights are stored in user_gdi_weights (one row per user).
"""

import uuid
import datetime
import logging
from dataclasses import dataclass
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

logger = logging.getLogger(__name__)

# ── Default (global) weights from gdi_service.py ──────────────────────────────
DEFAULT_ALPHA =  0.4
DEFAULT_BETA  = -0.2
DEFAULT_GAMMA = -0.2
DEFAULT_DELTA = -0.3

LEARNING_RATE = 0.05   # how fast weights shift per outcome signal
MIN_WEIGHT    = 0.05   # no weight can collapse to zero
MAX_UPDATES_FOR_FULL_ADAPTATION = 20  # after this many signals, trust user weights fully


@dataclass
class GDIWeights:
    alpha: float = DEFAULT_ALPHA
    beta:  float = DEFAULT_BETA
    gamma: float = DEFAULT_GAMMA
    delta: float = DEFAULT_DELTA
    update_count: int = 0

    def is_adapted(self) -> bool:
        """True once we have enough signals to trust personalized weights."""
        return self.update_count >= 5


@dataclass
class GDIResult:
    score: float
    state: str         # ENGAGED | WAVERING | SILENT_RECESS
    intervention: str  # NONE | SOFT_NUDGE | ROADMAP_ADJUST
    weights: GDIWeights
    components: dict


def classify_state(score: float) -> tuple[str, str]:
    if score > 0.10:
        return "ENGAGED", "NONE"
    elif score > -0.20:
        return "WAVERING", "SOFT_NUDGE"
    else:
        return "SILENT_RECESS", "ROADMAP_ADJUST"


class AdaptiveGDI:
    """Per-user adaptive GDI with online weight learning."""

    @staticmethod
    async def get_weights(db: AsyncSession, user_id: uuid.UUID) -> GDIWeights:
        """
        Load per-user GDI weights. Returns global defaults for new users.
        Lazy-imports the model to avoid circular imports.
        """
        try:
            from app.domain.models import UserGDIWeights
            result = await db.execute(
                select(UserGDIWeights).where(UserGDIWeights.user_id == user_id)
            )
            row = result.scalar_one_or_none()
            if row is None:
                return GDIWeights()
            return GDIWeights(
                alpha=row.alpha,
                beta=row.beta,
                gamma=row.gamma,
                delta=row.delta,
                update_count=row.update_count,
            )
        except Exception as e:
            logger.warning("adaptive_gdi: falling back to defaults (%s)", e)
            return GDIWeights()

    @staticmethod
    async def compute(
        db: AsyncSession,
        user_id: uuid.UUID,
        m_t: float,
        v_t: float,
        c_t: float,
        d_t: float,
    ) -> GDIResult:
        """Compute GDI score using this user's personalized weights."""
        weights = await AdaptiveGDI.get_weights(db, user_id)

        score = (
            weights.alpha * m_t
            + weights.beta  * v_t
            + weights.gamma * c_t
            + weights.delta * d_t
        )
        state, intervention = classify_state(score)

        return GDIResult(
            score=round(score, 4),
            state=state,
            intervention=intervention,
            weights=weights,
            components={"m_t": m_t, "v_t": v_t, "c_t": c_t, "d_t": d_t},
        )

    @staticmethod
    async def record_outcome(
        db: AsyncSession,
        user_id: uuid.UUID,
        outcome: str,   # "milestone_completed" | "goal_completed" | "churned"
        gdi_score_at_time: float,
    ) -> None:
        """
        Update per-user weights based on observed outcome vs prediction.
        Called from claim-task (milestone_completed / goal_completed)
        and from the nightly sweep for churn detection.
        """
        try:
            from app.domain.models import UserGDIWeights

            weights = await AdaptiveGDI.get_weights(db, user_id)

            # Direction: did the outcome confirm or contradict the prediction?
            # If user completed milestone but score was low → momentum underweighted
            # If user churned but score was high → decay underweighted
            if outcome in ("milestone_completed", "goal_completed"):
                if gdi_score_at_time <= 0.10:  # We under-predicted engagement
                    delta_alpha =  LEARNING_RATE
                    delta_delta = -LEARNING_RATE * 0.5
                else:
                    delta_alpha = 0.0
                    delta_delta = 0.0
            elif outcome == "churned":
                if gdi_score_at_time > -0.20:  # We over-predicted engagement
                    delta_alpha = -LEARNING_RATE * 0.5
                    delta_delta =  LEARNING_RATE
                else:
                    delta_alpha = 0.0
                    delta_delta = 0.0
            else:
                return

            # Apply updates with clamping
            new_alpha = max(MIN_WEIGHT, min(0.6,  weights.alpha + delta_alpha))
            new_delta = min(-MIN_WEIGHT, max(-0.6, weights.delta + delta_delta))

            # Normalize so |alpha| + |beta| + |gamma| + |delta| stays ~1.1
            # (same as defaults: 0.4+0.2+0.2+0.3=1.1)
            total = new_alpha + abs(weights.beta) + abs(weights.gamma) + abs(new_delta)
            scale = 1.1 / total if total > 0 else 1.0
            new_alpha = round(new_alpha * scale, 4)
            new_delta = round(new_delta * scale * -1, 4) * -1

            # Upsert weights
            result = await db.execute(
                select(UserGDIWeights).where(UserGDIWeights.user_id == user_id)
            )
            row = result.scalar_one_or_none()

            now = datetime.datetime.now(datetime.timezone.utc)
            if row is None:
                from app.domain.models import UserGDIWeights as W
                db.add(W(
                    user_id=user_id,
                    alpha=new_alpha,
                    beta=weights.beta,
                    gamma=weights.gamma,
                    delta=new_delta,
                    update_count=1,
                    updated_at=now,
                ))
            else:
                await db.execute(
                    update(UserGDIWeights)
                    .where(UserGDIWeights.user_id == user_id)
                    .values(
                        alpha=new_alpha,
                        delta=new_delta,
                        update_count=row.update_count + 1,
                        updated_at=now,
                    )
                )
            await db.commit()
            logger.info("AdaptiveGDI: updated weights for user %s (outcome=%s)", user_id, outcome)

        except Exception as e:
            logger.warning("AdaptiveGDI: weight update failed, skipping (%s)", e)
            await db.rollback()
