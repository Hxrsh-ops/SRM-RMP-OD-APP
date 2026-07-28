from uuid import UUID
from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict
from ..models.enums import OdStatus
from .attachment import AttachmentResponse
from .timeline import TimelineEventResponse, CommentResponse

class OdRequestCreate(BaseModel):
    reason: str
    start_date: date
    end_date: date
    duration_days: int
    purpose: str
    venue: str
    organizer: str
    additional_notes: Optional[str] = None
    attachments: Optional[List[AttachmentResponse]] = []

class FacultyActionRequest(BaseModel):
    approve: bool
    comment: Optional[str] = None

class CoordinatorActionRequest(BaseModel):
    approve: bool
    return_for_correction: bool = False
    comment: Optional[str] = None

class OdRequestResponse(BaseModel):
    id: str
    student_id: UUID
    reason: str
    start_date: date
    end_date: date
    duration_days: int
    purpose: str
    venue: str
    organizer: str
    additional_notes: Optional[str] = None
    faculty_id: UUID
    status: OdStatus
    attachments: List[AttachmentResponse] = []
    timeline: List[TimelineEventResponse] = []
    comments: List[CommentResponse] = []
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
