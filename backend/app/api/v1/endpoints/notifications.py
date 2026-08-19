from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from ....core.database import get_db
from ....core.exceptions import NotFoundException
from ....repositories.notification_repository import NotificationRepository
from ....services.notification_service import NotificationService
from ....schemas.notification import NotificationResponse
from ....models.user import User
from ...dependencies import get_current_user

router = APIRouter()

class BulkDeleteNotificationSchema(BaseModel):
    ids: Optional[List[UUID]] = None

@router.get("", response_model=List[NotificationResponse])
def get_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    noti_repo = NotificationRepository(db)
    noti_service = NotificationService(noti_repo)
    return noti_service.get_user_notifications(current_user.id)

@router.patch("/mark-read")
@router.post("/mark-read")
def mark_all_notifications_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    noti_repo = NotificationRepository(db)
    noti_service = NotificationService(noti_repo)
    noti_service.mark_all_as_read(current_user.id)
    return {"message": "Notifications marked as read"}

@router.delete("/{notification_id}", status_code=status.HTTP_200_OK)
def delete_notification(
    notification_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    noti_repo = NotificationRepository(db)
    noti_service = NotificationService(noti_repo)
    success = noti_service.delete_notification(notification_id, current_user.id)
    if not success:
        raise NotFoundException("Notification not found")
    return {"message": "Notification deleted successfully"}

@router.delete("", status_code=status.HTTP_200_OK)
@router.post("/bulk-delete", status_code=status.HTTP_200_OK)
def bulk_delete_notifications(
    body: Optional[BulkDeleteNotificationSchema] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    noti_repo = NotificationRepository(db)
    noti_service = NotificationService(noti_repo)
    ids = body.ids if body else None
    count = noti_service.delete_notifications_bulk(current_user.id, ids)
    return {"message": f"Deleted {count} notification(s)"}
