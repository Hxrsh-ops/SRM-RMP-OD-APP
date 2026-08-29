import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
import enum
from ..core.database import Base
from .guid import GUID
from .base import AuditMixin, SoftDeleteMixin

class ClearanceShareStatus(str, enum.Enum):
    SENT = "SENT"
    ACKNOWLEDGED = "ACKNOWLEDGED"

class SharedOdClearance(Base, AuditMixin, SoftDeleteMixin):
    __tablename__ = "shared_od_clearances"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    od_request_id = Column(String(50), ForeignKey("od_requests.id"), nullable=False, index=True)
    student_id = Column(GUID, ForeignKey("users.id"), nullable=False, index=True)
    faculty_id = Column(GUID, ForeignKey("users.id"), nullable=True, index=True)
    faculty_email = Column(String(100), nullable=False)
    faculty_name = Column(String(100), nullable=True)
    status = Column(SQLEnum(ClearanceShareStatus), default=ClearanceShareStatus.SENT, nullable=False)
    acknowledged_at = Column(DateTime(timezone=True), nullable=True)
    notes = Column(String(255), nullable=True)

    od_request = relationship("OdRequest", back_populates="shared_clearances")
    student = relationship("User", foreign_keys=[student_id])
    faculty = relationship("User", foreign_keys=[faculty_id])
