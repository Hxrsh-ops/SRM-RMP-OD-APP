from typing import Optional, List
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import or_
from ..models.user import User
from ..models.enums import UserRole

class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, user_id: UUID) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id, User.is_deleted == False).first()

    def get_by_username(self, username: str) -> Optional[User]:
        return self.db.query(User).filter(or_(User.username == username, User.email == username), User.is_deleted == False).first()

    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email, User.is_deleted == False).first()

    def get_by_role(self, role: UserRole, department_id: Optional[UUID] = None) -> Optional[User]:
        query = self.db.query(User).filter(User.role == role, User.is_deleted == False)
        if department_id:
            query = query.filter(User.department_id == department_id)
        return query.first()

    def create(self, user: User) -> User:
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
