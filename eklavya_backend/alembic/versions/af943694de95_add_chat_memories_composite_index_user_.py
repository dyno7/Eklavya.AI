"""add chat_memories composite index user_id_created_at

Revision ID: af943694de95
Revises: 7839e489928b
Create Date: 2026-06-09 12:09:04.141182

"""
from typing import Sequence, Union

from alembic import op


revision: str = 'af943694de95'
down_revision: Union[str, Sequence[str], None] = '7839e489928b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index(
        'idx_chat_memories_user_created_at',
        'chat_memories',
        ['user_id', 'created_at'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index('idx_chat_memories_user_created_at', table_name='chat_memories')
