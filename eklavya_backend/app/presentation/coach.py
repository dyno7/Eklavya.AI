import uuid
from typing import Dict

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.agents.coach_agent import CoachAgent
from app.core.auth import CurrentUser, get_current_user, get_current_user_id
from app.core.database import get_db
from app.core.gdi_service import GdiService
from app.core import repositories as repo

router = APIRouter(prefix="/api/v1/coach", tags=["Coach"])

# ─── In-memory Coach sessions ───────────────────────
# Keyed by session_id (not user_id) so task-specific sessions are independent.
_coach_sessions: dict[str, CoachAgent] = {}


class CoachStatusResponse(BaseModel):
    gdi_score: float
    state: str
    intervention: str
    components: Dict[str, float]


class CoachAskRequest(BaseModel):
    message: str
    session_id: str | None = None
    task_title: str | None = None
    task_description: str | None = None
    task_type: str | None = None
    milestone_title: str | None = None


class CoachAskResponse(BaseModel):
    reply: str
    session_id: str
    resources: list[dict] | None = None


@router.get("/status", response_model=CoachStatusResponse)
async def get_coach_status(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """JIT calculates the Goal Drift Index and Kalman Filter state for the Coach UI."""
    return await GdiService.calculate_current_gdi(db, current_user.id)


@router.post("/ask", response_model=CoachAskResponse)
async def ask_coach(
    request: CoachAskRequest,
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Ask the Learning Coach a question about a specific task or concept."""
    # Resolve or create session
    if request.session_id and request.session_id in _coach_sessions:
        session_id = request.session_id
        agent = _coach_sessions[session_id]
    else:
        session_id = str(uuid.uuid4())
        agent = CoachAgent(
            task_title=request.task_title,
            task_description=request.task_description,
            task_type=request.task_type,
            milestone_title=request.milestone_title,
        )
        _coach_sessions[session_id] = agent

    reply = await agent.ask(request.message)
    resources = CoachAgent.parse_resources(reply) or None

    # Persist to chat memory with a coach prefix on session_id for separation
    try:
        coach_session_uuid = uuid.UUID(session_id)
        await repo.add_chat_memory(db, current_user.id, "user", request.message, session_id=coach_session_uuid)
        await repo.add_chat_memory(db, current_user.id, "assistant", reply, session_id=coach_session_uuid)
    except Exception:
        pass

    return CoachAskResponse(reply=reply, session_id=session_id, resources=resources)
