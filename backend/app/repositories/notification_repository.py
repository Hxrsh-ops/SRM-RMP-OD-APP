from typing import List
from uuid import UUID
from sqlalchemy.orm import Session
from ..models.notification import Notification

class NotificationRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, notification: Notification) -> Notification:
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def list_by_recipient(self, recipient_id: UUID) -> List[Notification]:
        return self.db.query(Notification).filter(
            Notification.recipient_id == recipient_id
        ).order_by(Notification.timestamp.desc()).all()

    def mark_all_read(self, recipient_id: UUID):
        self.db.query(Notification).filter(
            Notification.recipient_id == recipient_id,
            Notification.is_read == False
        ).update({"is_read": True})
        self.db.commit()

    def delete_by_id(self, notification_id: UUID, recipient_id: UUID) -> bool:
        noti = self.db.query(Notification).filter(
            Notification.id == notification_id,
            Notification.recipient_id == recipient_id
        ).first()
        if not noti:
            return False
        self.db.delete(noti)
        self.db.commit()
        return True

    def delete_bulk(self, recipient_id: UUID, notification_ids: List[UUID] = None) -> int:
        query = self.db.query(Notification).filter(Notification.recipient_id == recipient_id)
        if notification_ids:
            query = query.filter(Notification.id.in_(notification_ids))
        deleted_count = query.delete(synchronize_session=False)
        self.db.commit()
        return deleted_count
