import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime, JSON, ForeignKey
from ..core.database import Base
from .guid import GUID

class SecurityEvent(Base):
    __tablename__ = "security_events"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    event_type = Column(String(50), nullable=False, index=True) # e.g. FAILED_LOGIN, ROLE_VIOLATION, EXPIRED_TOKEN, UPLOAD_VIOLATION, SUSPICIOUS_ACTIVITY, ACCOUNT_LOCKED
    severity = Column(String(20), nullable=False, default="INFO") # INFO, WARNING, CRITICAL
    
    username = Column(String(100), nullable=True, index=True)
    user_id = Column(GUID, ForeignKey("users.id"), nullable=True)
    
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    endpoint = Column(String(255), nullable=True)
    
    details = Column(JSON, nullable=True)
    timestamp = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
