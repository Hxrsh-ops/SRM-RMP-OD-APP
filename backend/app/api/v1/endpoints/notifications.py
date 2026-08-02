from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ....core.database import get_db
from ....repositories.notification_repository import NotificationRepository
from ....services.notification_service import NotificationService
from ....schemas.notification import NotificationResponse
from ....models.user import User
from ...dependencies import get_current_user

router = APIRouter()

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
