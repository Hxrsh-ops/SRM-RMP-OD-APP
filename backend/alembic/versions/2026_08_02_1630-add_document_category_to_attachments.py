"""Add document_category to attachments

Revision ID: d03883752054
Revises: c02772641943
Create Date: 2026-08-02 16:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = 'd03883752054'
down_revision: Union[str, None] = 'c02772641943'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.add_column('attachments', sa.Column('document_category', sa.String(length=50), nullable=True, server_default='supporting_document'))

def downgrade() -> None:
    op.drop_column('attachments', 'document_category')
