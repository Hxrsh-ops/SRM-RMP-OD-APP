from typing import Optional
from uuid import UUID
from sqlalchemy.orm import Session
from ..models.audit_log import AuditLog

class AuditLogRepository:
    def __init__(self, db: Session):
        self.db = db

    def log(
        self,
        action: str,
        resource_type: str,
        actor_id: Optional[UUID] = None,
        resource_id: Optional[str] = None,
        request_id: Optional[str] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        details: Optional[dict] = None
    ) -> AuditLog:
        entry = AuditLog(
            actor_id=actor_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            request_id=request_id,
            ip_address=ip_address,
            user_agent=user_agent,
            details=details
        )
        self.db.add(entry)
        self.db.commit()
        self.db.refresh(entry)
        return entry
