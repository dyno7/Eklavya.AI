from typing import Any, Dict
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.core.auth import CurrentUser, get_current_user
from app.core.database import get_db
from app.core.gdi_service import GdiService

router = APIRouter(prefix="/api/v1/coach", tags=["Coach"])

class CoachStatusResponse(BaseModel):
    gdi_score: float
    state: str
    intervention: str
    components: Dict[str, float]

@router.get("/status", response_model=CoachStatusResponse)
async def get_coach_status(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """JIT calculates the Goal Drift Index and Kalman Filter state for the Coach UI."""
    return await GdiService.calculate_current_gdi(db, current_user.id)
