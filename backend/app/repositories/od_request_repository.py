from typing import Optional, List
from uuid import UUID
from sqlalchemy.orm import Session
from ..models.od_request import OdRequest
from ..models.enums import OdStatus

class OdRequestRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, request_id: str) -> Optional[OdRequest]:
        return self.db.query(OdRequest).filter(OdRequest.id == request_id, OdRequest.is_deleted == False).first()

    def list_all(self) -> List[OdRequest]:
        return self.db.query(OdRequest).filter(OdRequest.is_deleted == False).order_by(OdRequest.created_at.desc()).all()

    def list_by_student(self, student_id: UUID) -> List[OdRequest]:
        return self.db.query(OdRequest).filter(
            OdRequest.student_id == student_id,
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_faculty_pending(self, faculty_id: UUID) -> List[OdRequest]:
        return self.db.query(OdRequest).filter(
            OdRequest.faculty_id == faculty_id,
            OdRequest.status.in_([OdStatus.PENDING_FACULTY, OdStatus.SUBMITTED]),
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def list_coordinator_pending(self) -> List[OdRequest]:
        return self.db.query(OdRequest).filter(
            OdRequest.status.in_([OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]),
            OdRequest.is_deleted == False
        ).order_by(OdRequest.created_at.desc()).all()

    def create(self, request: OdRequest) -> OdRequest:
        self.db.add(request)
        self.db.commit()
        self.db.refresh(request)
        return request

    def update(self, request: OdRequest) -> OdRequest:
        self.db.commit()
        self.db.refresh(request)
        return request
