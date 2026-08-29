import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from ..core.database import Base
from .guid import GUID
from .base import AuditMixin

class Comment(Base, AuditMixin):
    __tablename__ = "comments"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    od_request_id = Column(String(50), ForeignKey("od_requests.id"), nullable=False)
    
    author_name = Column(String(100), nullable=False)
    author_role = Column(String(30), nullable=False)
    text = Column(Text, nullable=False)
    timestamp = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    od_request = relationship("OdRequest", back_populates="comments")
