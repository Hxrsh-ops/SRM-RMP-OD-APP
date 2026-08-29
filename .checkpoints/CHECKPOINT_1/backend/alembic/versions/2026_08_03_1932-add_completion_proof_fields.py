"""add_completion_proof_fields

Revision ID: 2026_08_03_1932
Revises: d03883752054
Create Date: 2026-08-03 19:32:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '2026_08_03_1932'
down_revision = 'd03883752054'
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.add_column('od_requests', sa.Column('completion_summary', sa.Text(), nullable=True))
    op.add_column('od_requests', sa.Column('completion_submitted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('od_requests', sa.Column('completion_verified_at', sa.DateTime(timezone=True), nullable=True))

def downgrade() -> None:
    op.drop_column('od_requests', 'completion_verified_at')
    op.drop_column('od_requests', 'completion_submitted_at')
    op.drop_column('od_requests', 'completion_summary')
