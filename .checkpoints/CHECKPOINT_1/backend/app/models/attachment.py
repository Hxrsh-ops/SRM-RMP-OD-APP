import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from ..core.database import Base
from .guid import GUID
from .base import AuditMixin, SoftDeleteMixin

class Attachment(Base, AuditMixin, SoftDeleteMixin):
    __tablename__ = "attachments"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    od_request_id = Column(String(50), ForeignKey("od_requests.id"), nullable=False)
    
    file_name = Column(String(255), nullable=False)
    file_type = Column(String(50), nullable=False)
    size_bytes = Column(Integer, nullable=False)
    file_url = Column(String(500), nullable=False)
    document_category = Column(String(50), nullable=True, default="supporting_document")
    
    uploaded_by = Column(String(100), nullable=False)
    uploaded_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    od_request = relationship("OdRequest", back_populates="attachments")
