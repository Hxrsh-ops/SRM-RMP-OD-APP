import uuid
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from ..core.database import Base
from .guid import GUID
from .base import AuditMixin, SoftDeleteMixin

class ClassSection(Base, AuditMixin, SoftDeleteMixin):
    __tablename__ = "class_sections"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    department_id = Column(GUID, ForeignKey("departments.id"), nullable=False)
    academic_year = Column(Integer, nullable=False, default=1) # 1, 2, 3, 4
    section = Column(String(20), nullable=False) # e.g. 'Sec A', 'Sec G'
    batch = Column(String(50), nullable=True) # e.g. '2024-2028'
    program = Column(String(100), nullable=True) # e.g. 'B.Tech CSE (AI & ML)'
    
    faculty_advisor_id = Column(GUID, ForeignKey("users.id"), nullable=True)

    department = relationship("Department", back_populates="class_sections")
    faculty_advisor = relationship("User", foreign_keys=[faculty_advisor_id])
    students = relationship("User", back_populates="class_section", foreign_keys="User.class_section_id")
