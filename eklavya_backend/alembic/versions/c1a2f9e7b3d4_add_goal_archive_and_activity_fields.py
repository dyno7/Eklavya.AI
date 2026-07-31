"""add goal archive and last_activity_at fields

Revision ID: c1a2f9e7b3d4
Revises: af943694de95
Create Date: 2026-07-10 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = 'c1a2f9e7b3d4'
down_revision: Union[str, Sequence[str], None] = 'af943694de95'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'goals',
        sa.Column('archived', sa.Boolean(), nullable=False, server_default=sa.text('false')),
    )
    op.add_column(
        'goals',
        sa.Column('archived_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        'goals',
        sa.Column(
            'last_activity_at',
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text('now()'),
        ),
    )
    # Backfill existing rows with a meaningful value rather than "now()".
    op.execute('UPDATE goals SET last_activity_at = created_at')


def downgrade() -> None:
    op.drop_column('goals', 'last_activity_at')
    op.drop_column('goals', 'archived_at')
    op.drop_column('goals', 'archived')
