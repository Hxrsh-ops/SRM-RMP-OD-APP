"""add force_password_change to users

Revision ID: 2026_08_07_1400
Revises: 2026_08_07_1117
Create Date: 2026-08-07 14:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '2026_08_07_1400'
down_revision = 'da1187d61e3e'
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.add_column('users', sa.Column('force_password_change', sa.Boolean(), nullable=False, server_default='true'))

def downgrade() -> None:
    op.drop_column('users', 'force_password_change')
