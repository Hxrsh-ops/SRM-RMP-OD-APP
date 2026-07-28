from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict
from ..models.enums import OdStatus

class TimelineEventResponse(BaseModel):
    id: UUID
    title: str
    actor_name: str
    actor_role: str
    status: OdStatus
    note: Optional[str] = None
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)

class CommentResponse(BaseModel):
    id: UUID
    author_name: str
    author_role: str
    text: str
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
