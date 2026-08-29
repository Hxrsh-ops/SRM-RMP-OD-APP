from typing import Optional, List
from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime

class ClassSectionBase(BaseModel):
    department_id: UUID
    academic_year: int # 1, 2, 3, 4
    section: str # 'Sec A', 'Sec G'
    batch: Optional[str] = None # '2024-2028'
    program: Optional[str] = None # 'B.Tech CSE (AI & ML)'
    faculty_advisor_id: Optional[UUID] = None

class ClassSectionCreate(ClassSectionBase):
    pass

class ClassSectionUpdate(BaseModel):
    section: Optional[str] = None
    academic_year: Optional[int] = None
    batch: Optional[str] = None
    program: Optional[str] = None
    faculty_advisor_id: Optional[UUID] = None

class ClassSectionResponse(ClassSectionBase):
    id: UUID
    created_at: datetime
    faculty_advisor_name: Optional[str] = None
    faculty_advisor_email: Optional[str] = None
    department_name: Optional[str] = None
    student_count: int = 0

    model_config = ConfigDict(from_attributes=True)
