import uuid
from sqlalchemy import Column, String, Date, Integer, Float, Text, DateTime, Enum as SQLEnum, ForeignKey
from sqlalchemy.orm import relationship
from ..core.database import Base
from .guid import GUID
from .enums import OdStatus
from .base import AuditMixin, SoftDeleteMixin

class OdRequest(Base, AuditMixin, SoftDeleteMixin):
    __tablename__ = "od_requests"

    id = Column(String(50), primary_key=True) # e.g. OD-2026-001
    student_id = Column(GUID, ForeignKey("users.id"), nullable=False, index=True)
    faculty_id = Column(GUID, ForeignKey("users.id"), nullable=False, index=True)
    
    reason = Column(String(100), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    duration_days = Column(Integer, nullable=False)
    
    purpose = Column(Text, nullable=False)
    venue = Column(String(255), nullable=True)
    organizer = Column(String(255), nullable=True)
    additional_notes = Column(Text, nullable=True)
    
    cgpa = Column(Float, nullable=True)
    attendance_percentage = Column(Float, nullable=True)
    residence_type = Column(String(50), nullable=True)
    parent_consent_url = Column(Text, nullable=True)
    
    faculty_approval_time = Column(DateTime(timezone=True), nullable=True)
    status = Column(SQLEnum(OdStatus), nullable=False, default=OdStatus.PENDING_FACULTY, index=True)

    # Post-Event Completion Proof Fields
    completion_summary = Column(Text, nullable=True)
    completion_submitted_at = Column(DateTime(timezone=True), nullable=True)
    completion_verified_at = Column(DateTime(timezone=True), nullable=True)

    student = relationship("User", foreign_keys=[student_id], back_populates="od_requests")
    faculty = relationship("User", foreign_keys=[faculty_id], back_populates="assigned_od_requests")
    
    attachments = relationship("Attachment", back_populates="od_request", cascade="all, delete-orphan")
    timeline = relationship("TimelineEvent", back_populates="od_request", cascade="all, delete-orphan", order_by="TimelineEvent.timestamp")
    comments = relationship("Comment", back_populates="od_request", cascade="all, delete-orphan", order_by="Comment.timestamp")
    shared_clearances = relationship("SharedOdClearance", back_populates="od_request", cascade="all, delete-orphan")
