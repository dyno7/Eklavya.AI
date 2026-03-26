"""
Chat API router — handles Guru Agent conversations.

Endpoints:
- POST /api/chat/send — Send a message, get an AI reply
- GET  /api/chat/history/{user_id} — Get conversation history
- POST /api/chat/reset/{user_id} — Reset conversation
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.agents.guru_agent import GuruAgent

router = APIRouter(prefix="/api/chat", tags=["chat"])

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
async def send_message(request: ChatSendRequest):
    """Send a message to the Guru Agent and get a reply."""
    agent = _get_or_create_agent(request.user_id, request.domain)

    reply, is_roadmap_ready = await agent.chat(request.message)

    return ChatSendResponse(
        reply=reply,
        is_roadmap_ready=is_roadmap_ready,
        roadmap=agent.roadmap if is_roadmap_ready else None,
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
