"""
Chat API router — handles Guru Agent conversations.

Endpoints:
- POST /api/chat/send — Send a message, get an AI reply
- GET  /api/chat/sessions — List past conversation sessions
- GET  /api/chat/sessions/{session_id} — Load messages for a session
- GET  /api/chat/history/{user_id} — Get conversation history (legacy)
- POST /api/chat/reset/{user_id} — Reset conversation
"""

import logging
import uuid
import traceback

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.agents.guru_agent import GuruAgent
from app.agents.roadmap_persistence import persist_roadmap
from app.core.auth import CurrentUser, get_current_user, get_current_user_id
from app.core.database import get_db
from app.core.gdi_service import GdiService
from app.core import repositories as repo

router = APIRouter(prefix="/api/chat", tags=["chat"])
logger = logging.getLogger(__name__)

# ─── In-memory session store (MVP) ──────────────────
_sessions: dict[str, GuruAgent] = {}


def _get_or_create_agent(
    session_key: str,
    user_id: str,
    domain: str,
    roadmap_context: str | None = None,
    memory_context: str | None = None,
    current_streak: int | None = None,
    coach_state: str | None = None,
) -> GuruAgent:
    """Get existing agent for a session or create a fresh one.

    Keyed by session_id so each new conversation (new UUID) gets a clean agent.
    This prevents old roadmap state from bleeding into new sessions.
    """
    if session_key not in _sessions:
        _sessions[session_key] = GuruAgent(
            domain=domain,
            user_id=user_id,
            roadmap_context=roadmap_context,
            memory_context=memory_context,
            current_streak=current_streak,
            coach_state=coach_state,
        )
    return _sessions[session_key]


# ─── Request / Response schemas ─────────────────────

class ChatSendRequest(BaseModel):
    message: str
    domain: str = "learning"
    session_id: str | None = None

    @classmethod
    def __get_validators__(cls):
        yield from super().__get_validators__()

    def model_post_init(self, __context) -> None:
        if len(self.message) > 5000:
            raise ValueError("Message must be 5000 characters or fewer")
        if not self.message.strip():
            raise ValueError("Message cannot be empty")
        allowed_domains = {"learning", "startup", "writing", "fitness", "custom"}
        if self.domain not in allowed_domains:
            raise ValueError(f"Domain must be one of: {allowed_domains}")


class ChatSendResponse(BaseModel):
    reply: str
    session_id: str
    is_roadmap_ready: bool = False
    roadmap: dict | None = None
    resources: list[dict] | None = None
    goal_id: str | None = None
    navigate_to_roadmap: bool = False
    options: list[str] | None = None


class ChatHistoryResponse(BaseModel):
    messages: list[dict]


class ChatMemoryResponse(BaseModel):
    messages: list[dict]


class ChatSessionItem(BaseModel):
    session_id: str
    title: str
    started_at: str | None = None
    last_message_at: str | None = None
    message_count: int = 0


class ChatSessionListResponse(BaseModel):
    sessions: list[ChatSessionItem]


class ChatSessionMessagesResponse(BaseModel):
    session_id: str
    messages: list[dict]


_RESOURCE_INTENT_KEYWORDS = frozenset([
    "resource", "resources", "link", "links", "tutorial", "tutorials",
    "watch", "read", "article", "video", "course", "learn from",
    "where to learn", "recommend", "suggestion", "what should i",
    "how do i learn", "study material", "reference", "documentation",
])


def _is_resource_request(message: str) -> bool:
    """Return True when the user message is asking for learning resources."""
    lower = message.lower()
    return any(kw in lower for kw in _RESOURCE_INTENT_KEYWORDS)


def _collect_resources(roadmap: dict | None, limit: int = 6) -> list[dict]:
    """Flatten the roadmap's task resources into a short list for chat UI."""
    if not roadmap:
        return []

    resources: list[dict] = []
    for milestone in roadmap.get("milestones", []):
        if not isinstance(milestone, dict):
            continue
        milestone_title = str(milestone.get("title", "Milestone"))
        for task in milestone.get("tasks", []):
            if not isinstance(task, dict):
                continue
            task_title = str(task.get("title", "Task"))
            for resource in task.get("resources", []):
                if not isinstance(resource, dict):
                    continue
                url = str(resource.get("url", "")).strip()
                if not url:
                    continue
                resources.append({
                    "title": str(resource.get("title", url)).strip() or url,
                    "url": url,
                    "task_title": task_title,
                    "milestone_title": milestone_title,
                })
                if len(resources) >= limit:
                    return resources

    return resources


async def _fetch_goal_resources(db: AsyncSession, user_id, limit: int = 6) -> list[dict]:
    """Fetch stored resources from the user's active goal metadata."""
    goals = await repo.get_goals_for_user(db, user_id)
    active = [g for g in goals if g.status.value == "active"]
    if not active:
        return []
    goal = active[0]
    raw: list[dict] = (goal.metadata_ or {}).get("resources", [])
    return [r for r in raw if isinstance(r, dict) and r.get("url")][:limit]


# ─── Endpoints ──────────────────────────────────────

@router.post("/send", response_model=ChatSendResponse)
async def send_message(
    request: ChatSendRequest,
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Send a message to the Guru Agent and get a reply."""
    current_user_id = current_user.id
    session_user_id = str(current_user_id)

    # Resolve or create session_id
    if request.session_id:
        session_id = uuid.UUID(request.session_id)
    else:
        session_id = uuid.uuid4()

    roadmap_context = None
    memory_context = None
    current_streak = 0
    coach_state = None
    try:
        user = await repo.get_user_profile(db, current_user_id)
        if user is None:
            user = await repo.upsert_user_profile(db, current_user_id, display_name=current_user.display_name)
        current_streak = user.current_streak or 0

        goals = await repo.get_goals_for_user(db, current_user_id)
        active_goals = [g for g in goals if g.status.value == "active"]
        if active_goals:
            roadmap_context = f"Active Goal Title: {active_goals[0].title}\nDescription: {active_goals[0].description}"

        gdi_state = await GdiService.calculate_current_gdi(db, current_user_id)
        coach_state = f"{gdi_state['state']} ({gdi_state['intervention']})"

        # Load this session's messages as memory context
        session_memories = await repo.get_session_messages(db, current_user_id, session_id)
        if session_memories:
            memory_lines = [f"- {m.role}: {m.content}" for m in session_memories[-12:]]
            memory_context = "\n".join(memory_lines)
    except Exception as e:
        logger.warning("Failed to load roadmap context: %s", e)
        await db.rollback()

    agent = _get_or_create_agent(
        str(session_id),       # key by session — each new chat gets a fresh agent
        session_user_id,
        request.domain,
        roadmap_context,
        memory_context,
        current_streak=current_streak,
        coach_state=coach_state,
    )

    reply, is_roadmap_ready, navigate_to_roadmap, options = await agent.chat(request.message)

    goal_id = None
    persistence_failed = False
    if is_roadmap_ready and agent.roadmap:
        try:
            goal_id_uuid = await persist_roadmap(db, current_user_id, agent.roadmap)
            goal_id = str(goal_id_uuid)
            logger.info("Roadmap persisted as goal %s", goal_id)
        except Exception as e:
            logger.error("Roadmap persistence failed: %s", e)
            logger.error(traceback.format_exc())
            await db.rollback()
            persistence_failed = True

    # If persistence failed, tell the frontend the roadmap is NOT ready so the
    # user doesn't get navigated to an empty Goals tab. Surface a clear message.
    if persistence_failed:
        is_roadmap_ready = False
        reply = (
            "I built your roadmap but couldn't save it just now — please try again "
            "in a moment, or let me know if you'd like to tweak anything first."
        )

    # Persist conversational memory with session_id
    try:
        await repo.add_chat_memory(db, current_user_id, "user", request.message, session_id=session_id)
        await repo.add_chat_memory(db, current_user_id, "assistant", reply, session_id=session_id)
    except Exception as e:
        logger.warning("Failed to persist chat memory: %s", e)
        await db.rollback()

    # Determine resources to return: roadmap-generated (on completion) or
    # DB-stored (when user asks for resources mid-conversation).
    response_resources: list[dict] | None = None
    if is_roadmap_ready:
        response_resources = _collect_resources(agent.roadmap) or None
    elif _is_resource_request(request.message):
        try:
            db_resources = await _fetch_goal_resources(db, current_user_id)
            response_resources = db_resources or None
        except Exception as e:
            logger.warning("Failed to fetch goal resources: %s", e)

    return ChatSendResponse(
        reply=reply,
        session_id=str(session_id),
        is_roadmap_ready=is_roadmap_ready,
        roadmap=agent.roadmap if is_roadmap_ready else None,
        resources=response_resources,
        goal_id=goal_id,
        navigate_to_roadmap=navigate_to_roadmap,
        options=options,
    )


@router.get("/sessions", response_model=ChatSessionListResponse)
async def list_sessions(
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """List past conversation sessions (newest first). ChatGPT-style."""
    sessions = await repo.get_chat_sessions(db, current_user_id)
    return ChatSessionListResponse(sessions=[ChatSessionItem(**s) for s in sessions])


@router.get("/sessions/{session_id}", response_model=ChatSessionMessagesResponse)
async def load_session(
    session_id: str,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Load all messages for a specific session."""
    messages = await repo.get_session_messages(db, current_user_id, uuid.UUID(session_id))
    return ChatSessionMessagesResponse(
        session_id=session_id,
        messages=[
            {
                "role": m.role,
                "content": m.content,
                "created_at": m.created_at.isoformat() if m.created_at else None,
            }
            for m in messages
        ],
    )


@router.get("/history", response_model=ChatHistoryResponse)
async def get_history(
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Get conversation history for the authenticated user."""
    user_key = str(current_user_id)
    if user_key not in _sessions:
        return ChatHistoryResponse(messages=[])
    return ChatHistoryResponse(messages=_sessions[user_key].get_history())


@router.get("/memory", response_model=ChatMemoryResponse)
async def get_memory(
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    memories = await repo.get_recent_chat_memories(db, current_user_id, limit=50)
    return ChatMemoryResponse(
        messages=[
            {
                "role": m.role,
                "content": m.content,
                "created_at": m.created_at.isoformat() if m.created_at else None,
            }
            for m in memories
        ]
    )


@router.post("/reset")
async def reset_session(
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Reset (clear) all Guru sessions for the authenticated user."""
    user_id_str = str(current_user_id)
    # Sessions are now keyed by session_id UUID strings — scan and purge by user_id
    to_delete = [k for k, agent in _sessions.items() if agent.user_id == user_id_str]
    for k in to_delete:
        del _sessions[k]
    return {"status": "ok", "message": f"Cleared {len(to_delete)} session(s)"}


# /debug endpoint REMOVED — it leaked Gemini API key prefix to unauthenticated callers.
