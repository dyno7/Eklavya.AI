"""
Pydantic schema for the Guru Agent's roadmap JSON.

Mirrors ROADMAP_JSON_SCHEMA in prompts.py. Passed as `response_schema` to the
Gemini JSON-mode follow-up call so the model is structurally constrained to
emit valid roadmap JSON, instead of relying on prompt instructions alone.
"""

from pydantic import BaseModel, Field


class ResourceSchema(BaseModel):
    title: str
    url: str


class TaskSchema(BaseModel):
    title: str
    description: str
    type: str = Field(description="One of: watch, read, practice, quiz, write, exercise, custom")
    xp_reward: int
    estimated_minutes: int
    resources: list[ResourceSchema] = Field(default_factory=list)


class MilestoneSchema(BaseModel):
    title: str
    order: int
    estimated_days: int
    narrative_arc: str = Field(description="One of: Setup, Rising Action, Climax, Shareability")
    tasks: list[TaskSchema]


class RoadmapSchema(BaseModel):
    title: str
    domain: str = Field(description="One of: learning, fitness, startup, finance, writing")
    estimated_weeks: int
    committed_minutes_per_day: int
    milestones: list[MilestoneSchema]
