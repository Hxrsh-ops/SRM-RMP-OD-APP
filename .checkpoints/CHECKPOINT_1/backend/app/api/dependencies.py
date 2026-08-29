import jwt
from typing import List, Callable
from uuid import UUID
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from ..core.config import settings
from ..core.database import get_db
from ..core.exceptions import CredentialsException, PermissionDeniedException
from ..repositories.user_repository import UserRepository
from ..models.user import User
from ..models.enums import UserRole

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
) -> User:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id_str: str = payload.get("sub")
        if user_id_str is None:
            raise CredentialsException()
        user_id = UUID(user_id_str)
    except jwt.PyJWTError:
        raise CredentialsException()

    user_repo = UserRepository(db)
    user = user_repo.get_by_id(user_id)
    if user is None or not user.is_active or user.is_locked:
        raise CredentialsException("User account is inactive, locked, or revoked")
    return user

def require_roles(allowed_roles: List[UserRole]) -> Callable:
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles and current_user.role != UserRole.MASTER_ADMIN:
            raise PermissionDeniedException(f"User role {current_user.role} does not have access to this endpoint")
        return current_user
    return role_checker
