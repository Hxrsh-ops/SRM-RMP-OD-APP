from uuid import UUID
from typing import List, Optional
from ..repositories.notification_repository import NotificationRepository
from ..models.notification import Notification

class NotificationService:
    def __init__(self, notification_repo: NotificationRepository):
        self.notification_repo = notification_repo

    def send_notification(
        self,
        recipient_id: UUID,
        title: str,
        message: str,
        request_id: Optional[str] = None
    ) -> Notification:
        noti = Notification(
            recipient_id=recipient_id,
            title=title,
            message=message,
            request_id=request_id
        )
        return self.notification_repo.create(noti)

    def get_user_notifications(self, recipient_id: UUID) -> List[Notification]:
        return self.notification_repo.list_by_recipient(recipient_id)

    def mark_all_as_read(self, recipient_id: UUID):
        self.notification_repo.mark_all_read(recipient_id)

    def delete_notification(self, notification_id: UUID, recipient_id: UUID) -> bool:
        return self.notification_repo.delete_by_id(notification_id, recipient_id)

    def delete_notifications_bulk(self, recipient_id: UUID, notification_ids: Optional[List[UUID]] = None) -> int:
        return self.notification_repo.delete_bulk(recipient_id, notification_ids)
