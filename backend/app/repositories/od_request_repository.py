from typing import Optional, List, Dict
from uuid import UUID
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload, selectinload
from ..models.od_request import OdRequest
from ..models.enums import OdStatus, WorkflowStatusGroups

class OdRequestRepository:
    def __init__(self, db: Session):
        self.db = db

    def _base_query(self):
        return self.db.query(OdRequest).options(
            joinedload(OdRequest.student),
            joinedload(OdRequest.faculty),
            selectinload(OdRequest.attachments),
            selectinload(OdRequest.timeline),
            selectinload(OdRequest.comments),
        )

    def get_by_id(self, request_id: str) -> Optional[OdRequest]:
        return self._base_query().filter(OdRequest.id == request_id, OdRequest.is_deleted == False).first()

    def list_all(self) -> List[OdRequest]:
        return self._base_query().filter(OdRequest.is_deleted == False).order_by(OdRequest.created_at.desc()).all()

    def list_by_student(self, student_id: UUID) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.student_id == student_id,
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_by_faculty_assigned(self, faculty_id: UUID) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.faculty_id == faculty_id,
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_faculty_pending(self, faculty_id: UUID) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.faculty_id == faculty_id,
            OdRequest.status.in_(WorkflowStatusGroups.FACULTY_PENDING),
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_faculty_all(self, faculty_id: UUID) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.faculty_id == faculty_id,
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_coordinator_pending(self) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.status.in_(WorkflowStatusGroups.COORDINATOR_PENDING),
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_coordinator_all(self) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def hard_delete(self, request_id: str) -> bool:
        req = self.db.query(OdRequest).filter(OdRequest.id == request_id).first()
        if not req:
            return False
        self.db.delete(req)
        self.db.commit()
        return True

    def count_by_status(self) -> Dict[str, int]:
        results = self.db.query(
            OdRequest.status, func.count(OdRequest.id)
        ).filter(
            OdRequest.is_deleted == False
        ).group_by(OdRequest.status).all()

        counts = {}
        for s, count in results:
            key = s.value if hasattr(s, 'value') else (s.name if hasattr(s, 'name') else str(s))
            counts[key.upper()] = count
        
        pending_coord = counts.get('PENDING_COORDINATOR', 0) + counts.get('FACULTY_APPROVED', 0)
        approved_awaiting = counts.get('APPROVED_AWAITING_EVIDENCE', 0)
        pending_evidence_coord = counts.get('PENDING_EVIDENCE_COORDINATOR', 0)
        completed = counts.get('COMPLETED', 0)
        total = sum(counts.values())

        return {
            "pending_coordinator_count": pending_coord,
            "approved_awaiting_evidence_count": approved_awaiting,
            "pending_evidence_coordinator_count": pending_evidence_coord,
            "completed_count": completed,
            "total_submissions_count": total,
        }

    def create(self, request: OdRequest) -> OdRequest:
        try:
            self.db.add(request)
            self.db.commit()
            return self.get_by_id(request.id) or request
        except Exception:
            self.db.rollback()
            raise

    def update(self, request: OdRequest) -> OdRequest:
        try:
            self.db.commit()
            return self.get_by_id(request.id) or request
        except Exception:
            self.db.rollback()
            raise
