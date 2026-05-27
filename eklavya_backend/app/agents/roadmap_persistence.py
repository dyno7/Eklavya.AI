"""
Roadmap persistence — converts a Guru Agent's generated roadmap JSON
into Goal + Milestone + Task records in the database.
"""

import logging
import traceback
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core import repositories as repo
from app.domain.enums import MilestoneStatus

logger = logging.getLogger(__name__)

# Valid task types that map to our TaskType enum in DB.
# Unsupported generated types are downgraded to "custom".
_VALID_TASK_TYPES = {"read", "watch", "practice", "quiz", "write", "exercise", "custom"}

# Valid domain values (matches Domain enum). LLMs sometimes emit invalid values
# (e.g., "AI/ML", "programming", "data science") — those get coerced to "learning".
_VALID_DOMAINS = {"learning", "fitness", "startup", "finance", "writing"}


def _coerce_domain(raw: str | None) -> str:
    """Map any LLM-emitted domain string to a valid Domain enum value."""
    if not raw:
        return "learning"
    cleaned = str(raw).strip().lower()
    if cleaned in _VALID_DOMAINS:
        return cleaned
    # Common LLM mistakes — bucket them sensibly
    fitness_keywords = ("fitness", "health", "exercise", "workout", "gym")
    startup_keywords = ("startup", "business", "entrepreneur")
    finance_keywords = ("finance", "money", "invest", "trading")
    writing_keywords = ("writing", "author", "novel", "blog", "content")
    if any(k in cleaned for k in fitness_keywords):
        return "fitness"
    if any(k in cleaned for k in startup_keywords):
        return "startup"
    if any(k in cleaned for k in finance_keywords):
        return "finance"
    if any(k in cleaned for k in writing_keywords):
        return "writing"
    return "learning"


async def persist_roadmap(
    db: AsyncSession,
    user_id: uuid.UUID,
    roadmap: dict,
) -> uuid.UUID:
    """
    Save a generated roadmap as a Goal with Milestones and Tasks.

    Args:
        db: async database session
        user_id: the user's UUID
        roadmap: the parsed roadmap dict from GuruAgent

    Returns:
        The created goal's UUID

    Raises:
        Exception: if goal creation itself fails. Individual milestone/task
        failures are logged but do not abort the whole roadmap.
    """
    # 1. Extract and aggregate resources for the goal-level metadata
    all_resources: list[dict] = []
    milestones = roadmap.get("milestones", [])
    for ms_data in milestones:
        if not isinstance(ms_data, dict):
            continue
        for t_data in ms_data.get("tasks", []):
            if not isinstance(t_data, dict):
                continue
            task_type_raw = str(t_data.get("type", "custom")).strip().lower()
            task_type = task_type_raw if task_type_raw in _VALID_TASK_TYPES else "custom"
            for r in t_data.get("resources", []):
                if not isinstance(r, dict):
                    continue
                r["type"] = task_type
                if len(all_resources) < 15:
                    all_resources.append(r)

    # 2. Create the Goal (must succeed for the rest to make sense)
    domain = _coerce_domain(roadmap.get("domain"))
    title = str(roadmap.get("title") or "My Learning Roadmap")[:500]
    estimated_weeks = roadmap.get("estimated_weeks") or "?"

    try:
        goal = await repo.create_goal(
            db,
            user_id=user_id,
            title=title,
            description=f"AI-generated roadmap • {estimated_weeks} weeks",
            domain=domain,
            metadata_={
                "source": "guru_agent",
                "estimated_weeks": roadmap.get("estimated_weeks"),
                "committed_minutes_per_day": roadmap.get("committed_minutes_per_day"),
                "resources": all_resources,
            },
        )
    except Exception as e:
        logger.error("Failed to create Goal: %s\n%s", e, traceback.format_exc())
        await db.rollback()
        raise

    logger.info("Created goal %s for user %s (domain=%s)", goal.id, user_id, domain)

    # 3. Create Milestones + Tasks (best-effort: skip individual failures)
    created_milestones = 0
    for ms_idx, ms_data in enumerate(milestones):
        if not isinstance(ms_data, dict):
            continue
        try:
            narrative_arc = str(ms_data.get("narrative_arc") or "").strip()
            ms_description = f"~{ms_data.get('estimated_days', '?')} days"
            if narrative_arc:
                ms_description = f"[{narrative_arc}] {ms_description}"

            milestone = await repo.create_milestone(
                db,
                goal_id=goal.id,
                title=str(ms_data.get("title") or f"Milestone {ms_idx + 1}")[:500],
                description=ms_description,
                order_index=int(ms_data.get("order", ms_idx + 1)),
            )

            if ms_idx == 0:
                await repo.update_milestone_status(db, milestone.id, MilestoneStatus.ACTIVE)

            for t_idx, task_data in enumerate(ms_data.get("tasks", [])):
                if not isinstance(task_data, dict):
                    continue
                try:
                    task_type_raw = str(task_data.get("type", "custom")).strip().lower()
                    task_type = task_type_raw if task_type_raw in _VALID_TASK_TYPES else "custom"
                    xp_reward = task_data.get("xp_reward", 10)
                    if not isinstance(xp_reward, int):
                        try:
                            xp_reward = int(xp_reward)
                        except (TypeError, ValueError):
                            xp_reward = 10

                    await repo.create_task(
                        db,
                        milestone_id=milestone.id,
                        title=str(task_data.get("title") or f"Task {t_idx + 1}")[:500],
                        description=str(task_data.get("description") or ""),
                        task_type=task_type,
                        xp_reward=xp_reward,
                        order_index=t_idx,
                        metadata_={
                            "estimated_minutes": task_data.get("estimated_minutes", 30),
                            "resources": task_data.get("resources", []),
                            "narrative_arc": narrative_arc or None,
                        },
                    )
                except Exception as e:
                    logger.error(
                        "Skipped task %d in milestone %s: %s", t_idx, milestone.id, e
                    )

            created_milestones += 1
        except Exception as e:
            logger.error(
                "Skipped milestone %d in goal %s: %s\n%s",
                ms_idx, goal.id, e, traceback.format_exc(),
            )

    logger.info("Persisted %d/%d milestones for goal %s", created_milestones, len(milestones), goal.id)
    return goal.id
