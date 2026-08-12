"""add task timer fields

Revision ID: 9f8e7d6c5b4a
Revises: c1a2f9e7b3d4
Create Date: 2026-08-12

Adds started_at, actual_minutes, and timer_running columns to the tasks table.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '9f8e7d6c5b4a'
down_revision: Union[str, None] = 'c1a2f9e7b3d4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('tasks', sa.Column('started_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('tasks', sa.Column('actual_minutes', sa.Integer(), nullable=True))
    op.add_column('tasks', sa.Column('timer_running', sa.Boolean(), nullable=False, server_default='false'))


def downgrade() -> None:
    op.drop_column('tasks', 'timer_running')
    op.drop_column('tasks', 'actual_minutes')
    op.drop_column('tasks', 'started_at')