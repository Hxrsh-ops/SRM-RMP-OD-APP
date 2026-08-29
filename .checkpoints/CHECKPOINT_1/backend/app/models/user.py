import uuid
from sqlalchemy import Column, String, Boolean, Integer, DateTime, Enum as SQLEnum, ForeignKey
from sqlalchemy.orm import relationship
from ..core.database import Base
from .guid import GUID
from .enums import UserRole
from .base import AuditMixin, SoftDeleteMixin

class User(Base, AuditMixin, SoftDeleteMixin):
    __tablename__ = "users"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False, index=True) # Register No or Employee ID
    email = Column(String(100), unique=True, nullable=False, index=True)
    full_name = Column(String(100), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(SQLEnum(UserRole), nullable=False, default=UserRole.STUDENT)
    
    department_id = Column(GUID, ForeignKey("departments.id"), nullable=True)
    program = Column(String(100), nullable=True) # e.g. B.Tech CSE (AI & ML)
    year_section = Column(String(50), nullable=True) # e.g. 2nd Year - Sec G
    
    assigned_faculty_id = Column(GUID, ForeignKey("users.id"), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    is_locked = Column(Boolean, default=False, nullable=False)
    force_password_change = Column(Boolean, default=True, nullable=False)
    failed_login_attempts = Column(Integer, default=0, nullable=False)
    last_login_at = Column(DateTime(timezone=True), nullable=True)

    department = relationship("Department", back_populates="users")
    assigned_faculty = relationship("User", remote_side=[id])
    
    od_requests = relationship("OdRequest", back_populates="student", foreign_keys="OdRequest.student_id")
    assigned_od_requests = relationship("OdRequest", back_populates="faculty", foreign_keys="OdRequest.faculty_id")
    notifications = relationship("Notification", back_populates="recipient")
