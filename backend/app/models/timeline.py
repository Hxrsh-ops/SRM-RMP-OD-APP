import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime, Enum as SQLEnum, ForeignKey
from sqlalchemy.orm import relationship
from ..core.database import Base
from .guid import GUID
from .enums import OdStatus
from .base import AuditMixin

class TimelineEvent(Base, AuditMixin):
    __tablename__ = "timeline_events"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    od_request_id = Column(String(50), ForeignKey("od_requests.id"), nullable=False)
    
    title = Column(String(100), nullable=False)
    actor_name = Column(String(100), nullable=False)
    actor_role = Column(String(30), nullable=False)
    status = Column(SQLEnum(OdStatus), nullable=False)
    note = Column(Text, nullable=True)
    timestamp = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    od_request = relationship("OdRequest", back_populates="timeline")
