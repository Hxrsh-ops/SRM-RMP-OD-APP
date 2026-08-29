from typing import Optional
from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime

class ShareClearanceRequest(BaseModel):
    faculty_email: str
    notes: Optional[str] = None

class SharedClearanceResponse(BaseModel):
    id: UUID
    od_request_id: str
    student_id: UUID
    student_name: Optional[str] = None
    student_reg_no: Optional[str] = None
    student_program: Optional[str] = None
    student_year_section: Optional[str] = None
    faculty_id: Optional[UUID] = None
    faculty_email: str
    faculty_name: Optional[str] = None
    reason: Optional[str] = None
    purpose: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    duration_days: Optional[int] = None
    venue: Optional[str] = None
    organizer: Optional[str] = None
    status: str
    acknowledged_at: Optional[datetime] = None
    notes: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
