from uuid import UUID
from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict
from ..models.enums import UserRole

class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: str
    role: UserRole
    program: Optional[str] = None
    year_section: Optional[str] = None

class UserCreate(UserBase):
    password: str
    department_id: Optional[UUID] = None

class UserResponse(UserBase):
    id: UUID
    is_active: bool
    force_password_change: bool = False
    assigned_faculty_id: Optional[UUID] = None
    assigned_faculty_name: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class LoginRequest(BaseModel):
    username: str
    password: str
    remember_me: bool = True

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
