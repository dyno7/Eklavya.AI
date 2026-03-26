"""
Roadmap persistence — converts a Guru Agent's generated roadmap JSON
into Goal + Milestone + Task records in the database.
"""

import logging
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core import repositories as repo

logger = logging.getLogger(__name__)

# Valid task types that map to our TaskType enum
_VALID_TASK_TYPES = {"read", "watch", "practice", "quiz", "write", "exercise", "custom"}


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
    """
    # 1. Create the Goal
    domain = roadmap.get("domain", "learning")
    goal = await repo.create_goal(
        db,
        user_id=user_id,
        title=roadmap.get("title", "My Learning Roadmap"),
        description=f"AI-generated roadmap • {roadmap.get('estimated_weeks', '?')} weeks",
        domain=domain,
        metadata_={
            "source": "guru_agent",
            "estimated_weeks": roadmap.get("estimated_weeks"),
        },
    )
    logger.info(f"Created goal {goal.id} for user {user_id}")

    # 2. Create Milestones + Tasks
    milestones = roadmap.get("milestones", [])
    for ms_data in milestones:
        milestone = await repo.create_milestone(
            db,
            goal_id=goal.id,
            title=ms_data.get("title", "Milestone"),
            description=f"~{ms_data.get('estimated_days', '?')} days",
            order_index=ms_data.get("order", 0),
        )

        tasks = ms_data.get("tasks", [])
        for idx, task_data in enumerate(tasks):
            task_type = task_data.get("type", "custom")
            if task_type not in _VALID_TASK_TYPES:
                task_type = "custom"

            await repo.create_task(
                db,
                milestone_id=milestone.id,
                title=task_data.get("title", "Task"),
                task_type=task_type,
                xp_reward=task_data.get("xp_reward", 10),
                order_index=idx,
                metadata_={
                    "estimated_minutes": task_data.get("estimated_minutes", 30),
                },
            )

    logger.info(f"Persisted {len(milestones)} milestones for goal {goal.id}")
    return goal.id
