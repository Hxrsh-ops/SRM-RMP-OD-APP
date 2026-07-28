from typing import Optional, List
from uuid import UUID
from sqlalchemy.orm import Session
from ..models.department import Department

class DepartmentRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, dept_id: UUID) -> Optional[Department]:
        return self.db.query(Department).filter(Department.id == dept_id, Department.is_deleted == False).first()

    def list_all(self) -> List[Department]:
        return self.db.query(Department).filter(Department.is_deleted == False).all()

    def create(self, department: Department) -> Department:
        self.db.add(department)
        self.db.commit()
        self.db.refresh(department)
        return department
