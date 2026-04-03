"""
Chat API router — handles Guru Agent conversations.

Endpoints:
- POST /api/chat/send — Send a message, get an AI reply
- GET  /api/chat/history/{user_id} — Get conversation history
- POST /api/chat/reset/{user_id} — Reset conversation
"""

import logging
import uuid

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.agents.guru_agent import GuruAgent
from app.agents.roadmap_persistence import persist_roadmap
from app.core.database import get_db
from app.core import repositories as repo

router = APIRouter(prefix="/api/chat", tags=["chat"])
logger = logging.getLogger(__name__)

# ─── In-memory session store (MVP) ──────────────────
# In production, this would be Redis or a database table.
_sessions: dict[str, GuruAgent] = {}


def _get_or_create_agent(user_id: str, domain: str) -> GuruAgent:
    """Get existing agent session or create a new one."""
    if user_id not in _sessions:
        _sessions[user_id] = GuruAgent(domain=domain, user_id=user_id)
    return _sessions[user_id]


# ─── Request / Response schemas ─────────────────────

class ChatSendRequest(BaseModel):
    message: str
    domain: str = "learning"
    user_id: str = "demo-user"  # Will come from auth in production


class ChatSendResponse(BaseModel):
    reply: str
    is_roadmap_ready: bool = False
    roadmap: dict | None = None
    goal_id: str | None = None


class ChatHistoryResponse(BaseModel):
    messages: list[dict]


# ─── Endpoints ──────────────────────────────────────

@router.post("/send", response_model=ChatSendResponse)
async def send_message(
    request: ChatSendRequest,
    db: AsyncSession = Depends(get_db),
):
    """Send a message to the Guru Agent and get a reply."""
    agent = _get_or_create_agent(request.user_id, request.domain)

    reply, is_roadmap_ready = await agent.chat(request.message)

    goal_id = None
    if is_roadmap_ready and agent.roadmap:
        # Persist the roadmap to the database
        try:
            user_uuid = uuid.UUID(request.user_id)
            # Ensure user exists before creating a Goal to prevent FK violations
            user = await repo.get_user_profile(db, user_uuid)
            if user is None:
                await repo.upsert_user_profile(db, user_uuid, display_name="User")
            
            goal_id_uuid = await persist_roadmap(db, user_uuid, agent.roadmap)
            goal_id = str(goal_id_uuid)
            logger.info(f"Roadmap persisted as goal {goal_id}")
        except (ValueError, Exception) as e:
            # user_id might not be a valid UUID in demo mode — skip persistence
            logger.warning(f"Skipped roadmap persistence: {e}")

    return ChatSendResponse(
        reply=reply,
        is_roadmap_ready=is_roadmap_ready,
        roadmap=agent.roadmap if is_roadmap_ready else None,
        goal_id=goal_id,
    )


@router.get("/history/{user_id}", response_model=ChatHistoryResponse)
async def get_history(user_id: str):
    """Get conversation history for a user session."""
    if user_id not in _sessions:
        return ChatHistoryResponse(messages=[])
    return ChatHistoryResponse(messages=_sessions[user_id].get_history())


@router.post("/reset/{user_id}")
async def reset_session(user_id: str):
    """Reset (clear) a user's conversation session."""
    if user_id in _sessions:
        _sessions[user_id].reset()
        del _sessions[user_id]
    return {"status": "ok", "message": f"Session for {user_id} has been reset"}


@router.get("/debug")
async def debug_status():
    """Non-authenticated debug endpoint — shows whether Gemini API is live or demo."""
    from app.core.config import get_settings
    settings = get_settings()
    return {
        "gemini_key_set": bool(settings.GEMINI_API_KEY),
        "gemini_key_preview": settings.GEMINI_API_KEY[:8] + "..." if settings.GEMINI_API_KEY else "NOT SET",
        "environment": settings.ENVIRONMENT,
    }
