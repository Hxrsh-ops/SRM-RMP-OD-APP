from uuid import UUID
from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, model_validator
from ..models.enums import OdStatus
from .attachment import AttachmentCreate, AttachmentResponse
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
    cgpa: Optional[float] = None
    attendance_percentage: Optional[float] = None
    residence_type: Optional[str] = "Day Scholar"
    parent_consent_url: Optional[str] = None
    attachments: Optional[List[AttachmentCreate]] = []

    @model_validator(mode="after")
    def validate_dates_and_duration(self):
        if self.end_date < self.start_date:
            raise ValueError("End date cannot be prior to start date.")
        expected_duration = (self.end_date - self.start_date).days + 1
        if self.duration_days <= 0 or self.duration_days != expected_duration:
            self.duration_days = expected_duration
        return self

class FacultyActionRequest(BaseModel):
    approve: bool
    comment: Optional[str] = None

class CoordinatorActionRequest(BaseModel):
    approve: bool
    return_for_correction: bool = False
    escalate_to: Optional[str] = None  # 'HOD' or 'DEAN'
    comment: Optional[str] = None

class CompletionEvidenceSubmit(BaseModel):
    completion_summary: str

class CoordinatorAnalyticsResponse(BaseModel):
    pending_coordinator_count: int
    approved_awaiting_evidence_count: int
    pending_evidence_coordinator_count: int
    completed_count: int
    total_submissions_count: int

class OdRequestResponse(BaseModel):
    id: str
    student_id: UUID
    student_name: Optional[str] = None
    register_number: Optional[str] = None
    program: Optional[str] = None
    year_section: Optional[str] = None
    student_email: Optional[str] = None
    reason: str
    start_date: date
    end_date: date
    duration_days: int
    purpose: str
    venue: str
    organizer: str
    additional_notes: Optional[str] = None
    cgpa: Optional[float] = None
    attendance_percentage: Optional[float] = None
    residence_type: Optional[str] = "Day Scholar"
    parent_consent_url: Optional[str] = None
    faculty_id: UUID
    faculty_advisor_name: Optional[str] = None
    faculty_approval_time: Optional[datetime] = None
    status: OdStatus
    completion_summary: Optional[str] = None
    completion_submitted_at: Optional[datetime] = None
    completion_verified_at: Optional[datetime] = None
    attachments: List[AttachmentResponse] = []
    timeline: List[TimelineEventResponse] = []
    comments: List[CommentResponse] = []
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
