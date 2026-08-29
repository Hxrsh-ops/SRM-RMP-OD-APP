from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict

class NotificationResponse(BaseModel):
    id: UUID
    recipient_id: UUID
    title: str
    message: str
    is_read: bool
    request_id: Optional[str] = None
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
