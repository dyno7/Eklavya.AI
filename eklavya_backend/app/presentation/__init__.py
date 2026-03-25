"""Presentation package — API routers."""

from app.presentation.goals import router as goals_router
from app.presentation.tasks import router as tasks_router
from app.presentation.users import router as users_router

__all__ = ["goals_router", "tasks_router", "users_router"]
