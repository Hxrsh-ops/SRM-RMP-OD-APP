from typing import Optional, List, Dict
from uuid import UUID
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload, selectinload
from ..models.od_request import OdRequest
from ..models.enums import OdStatus

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

    def list_faculty_pending(self, faculty_id: UUID) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.faculty_id == faculty_id,
            OdRequest.status.in_([
                OdStatus.PENDING_FACULTY,
                OdStatus.SUBMITTED,
                OdStatus.PENDING_EVIDENCE_FACULTY
            ]),
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_coordinator_pending(self) -> List[OdRequest]:
        return self._base_query().filter(
            OdRequest.status.in_([
                OdStatus.PENDING_COORDINATOR,
                OdStatus.FACULTY_APPROVED,
                OdStatus.PENDING_EVIDENCE_COORDINATOR
            ]),
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def count_by_status(self) -> Dict[str, int]:
        results = self.db.query(
            OdRequest.status, func.count(OdRequest.id)
        ).filter(
            OdRequest.is_deleted == False
        ).group_by(OdRequest.status).all()

        counts = {s.name: count for s, count in results}
        
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
        self.db.add(request)
        self.db.commit()
        return self.get_by_id(request.id) or request

    def update(self, request: OdRequest) -> OdRequest:
        self.db.commit()
        return self.get_by_id(request.id) or request
