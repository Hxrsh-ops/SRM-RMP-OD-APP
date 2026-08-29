from typing import List
from uuid import UUID
from sqlalchemy.orm import Session
from ..models.attachment import Attachment

class AttachmentRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, attachment: Attachment) -> Attachment:
        self.db.add(attachment)
        self.db.commit()
        self.db.refresh(attachment)
        return attachment

    def list_by_request(self, request_id: str) -> List[Attachment]:
        return self.db.query(Attachment).filter(
            Attachment.od_request_id == request_id,
            Attachment.is_deleted == False
        ).all()
