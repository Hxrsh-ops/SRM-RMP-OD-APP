import uuid
from sqlalchemy import Column, String
from sqlalchemy.orm import relationship
from ..core.database import Base
from .guid import GUID
from .base import AuditMixin, SoftDeleteMixin

class Department(Base, AuditMixin, SoftDeleteMixin):
    __tablename__ = "departments"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    name = Column(String(100), unique=True, nullable=False)
    code = Column(String(20), unique=True, nullable=False)

    users = relationship("User", back_populates="department")
    class_sections = relationship("ClassSection", back_populates="department", cascade="all, delete-orphan")
