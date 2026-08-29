"""sync_odstatus_postgres_enum_values

Revision ID: 2026_08_06_1800
Revises: 2026_08_03_1932
Create Date: 2026-08-06 18:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '2026_08_06_1800'
down_revision = '2026_08_03_1932'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Safely synchronize native PostgreSQL 'odstatus' enum type values
    statuses = [
        'SUBMITTED',
        'PENDING_FACULTY',
        'FACULTY_APPROVED',
        'FACULTY_REJECTED',
        'PENDING_COORDINATOR',
        'APPROVED_AWAITING_EVIDENCE',
        'PENDING_EVIDENCE_FACULTY',
        'PENDING_EVIDENCE_COORDINATOR',
        'EVIDENCE_REVISION_REQUESTED',
        'COMPLETED',
        'REJECTED',
        'REVISION_REQUESTED',
    ]
    for status_val in statuses:
        op.execute(f"ALTER TYPE odstatus ADD VALUE IF NOT EXISTS '{status_val}'")

def downgrade() -> None:
    # PostgreSQL does not natively support removing values from ENUM types without recreate
    pass
