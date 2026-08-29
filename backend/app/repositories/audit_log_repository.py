from typing import Optional, List
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import func
from ..models.audit_log import AuditLog

class AuditLogRepository:
    MAX_LOGS_RETENTION: int = 2500

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

        # Automated pruning to prevent table bloating
        self._auto_prune_if_needed()
        return entry

    def prune_old_logs(self, keep_latest: int = 2500) -> int:
        """Prunes old audit logs beyond the latest keep_latest records."""
        try:
            total = self.db.query(func.count(AuditLog.id)).scalar() or 0
            if total <= keep_latest:
                return 0

            cutoff_log = (
                self.db.query(AuditLog.created_at)
                .order_by(AuditLog.created_at.desc())
                .offset(keep_latest)
                .first()
            )
            if cutoff_log and cutoff_log[0]:
                cutoff_time = cutoff_log[0]
                deleted = (
                    self.db.query(AuditLog)
                    .filter(AuditLog.created_at <= cutoff_time)
                    .delete(synchronize_session=False)
                )
                self.db.commit()
                return deleted
        except Exception:
            self.db.rollback()
        return 0

    def _auto_prune_if_needed(self):
        """Auto-prune threshold check with buffer to avoid running on every single insert."""
        try:
            count = self.db.query(func.count(AuditLog.id)).scalar() or 0
            if count > self.MAX_LOGS_RETENTION + 50:
                self.prune_old_logs(self.MAX_LOGS_RETENTION)
        except Exception:
            self.db.rollback()
