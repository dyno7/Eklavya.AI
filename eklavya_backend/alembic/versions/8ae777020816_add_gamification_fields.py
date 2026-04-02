"""add gamification fields

Revision ID: 8ae777020816
Revises:
Create Date: 2026-04-02

Adds total_xp and current_streak columns to the users table.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '8ae777020816'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('total_xp', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('users', sa.Column('current_streak', sa.Integer(), nullable=False, server_default='0'))


def downgrade() -> None:
    op.drop_column('users', 'current_streak')
    op.drop_column('users', 'total_xp')
