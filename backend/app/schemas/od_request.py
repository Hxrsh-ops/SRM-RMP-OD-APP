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
    cgpa: Optional[float] = 8.5
    attendance_percentage: Optional[float] = 88.0
    residence_type: Optional[str] = "Day Scholar"
    parent_consent_url: Optional[str] = None
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
    student_name: Optional[str] = "K.M. Harshanth"
    register_number: Optional[str] = "RA2511026020400"
    program: Optional[str] = "B.Tech CSE (AI & ML)"
    year_section: Optional[str] = "2nd Year - Sec G"
    student_email: Optional[str] = "hk7793@srmist.edu.in"
    reason: str
    start_date: date
    end_date: date
    duration_days: int
    purpose: str
    venue: str
    organizer: str
    additional_notes: Optional[str] = None
    cgpa: Optional[float] = 8.5
    attendance_percentage: Optional[float] = 88.0
    residence_type: Optional[str] = "Day Scholar"
    parent_consent_url: Optional[str] = None
    faculty_id: UUID
    faculty_advisor_name: Optional[str] = "Dr. Karthik B (Mock)"
    faculty_approval_time: Optional[datetime] = None
    status: OdStatus
    attachments: List[AttachmentResponse] = []
    timeline: List[TimelineEventResponse] = []
    comments: List[CommentResponse] = []
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
