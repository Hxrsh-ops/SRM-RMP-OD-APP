from typing import Tuple, Optional
from uuid import UUID
from sqlalchemy.orm import Session
from ..core.security import verify_password, get_password_hash, create_access_token, create_refresh_token
from ..core.exceptions import CredentialsException, BadRequestException
from ..repositories.user_repository import UserRepository
from ..models.user import User
from ..schemas.token import Token
from ..schemas.user import LoginRequest, UserCreate

class AuthService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    def authenticate_user(self, username: str, password: str) -> User:
        user = self.user_repo.get_by_username(username.strip())
        if not user or not user.is_active:
            raise CredentialsException("Invalid Register Number / Employee ID or password")
        
        if getattr(user, "is_locked", False):
            from ..models.security_event import SecurityEvent
            sec_event = SecurityEvent(
                event_type="ACCOUNT_LOCKED_ATTEMPT",
                severity="WARNING",
                username=username,
                user_id=user.id,
                details={"reason": "User attempted login while account was locked"}
            )
            self.user_repo.db.add(sec_event)
            self.user_repo.db.commit()
            raise CredentialsException("Account is locked due to security policy. Contact administrator.")

        if not verify_password(password.strip(), user.hashed_password):
            user.failed_login_attempts = getattr(user, "failed_login_attempts", 0) + 1
            from ..models.enums import UserRole
            if user.failed_login_attempts >= 5 and user.role != UserRole.MASTER_ADMIN:
                user.is_locked = True

            from ..models.security_event import SecurityEvent
            sec_event = SecurityEvent(
                event_type="FAILED_LOGIN",
                severity="WARNING",
                username=username,
                user_id=user.id,
                details={"attempts": user.failed_login_attempts, "role": user.role.value if hasattr(user.role, "value") else str(user.role)}
            )
            self.user_repo.db.add(sec_event)
            self.user_repo.db.commit()
            raise CredentialsException("Invalid Register Number / Employee ID or password")

        # Reset failed attempts on success
        user.failed_login_attempts = 0
        import datetime
        user.last_login_at = datetime.datetime.now(datetime.timezone.utc)
        self.user_repo.db.commit()
        return user

    def login(self, login_data: LoginRequest) -> Tuple[Token, User]:
        user = self.authenticate_user(login_data.username, login_data.password)
        access_token = create_access_token(subject=user.id, role=user.role.value)
        refresh_token = create_refresh_token(subject=user.id)
        
        token_payload = Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer"
        )
        return token_payload, user

    def register_user(self, user_in: UserCreate) -> User:
        if self.user_repo.get_by_username(user_in.username):
            raise BadRequestException("Username / Register Number already exists")
        if self.user_repo.get_by_email(user_in.email):
            raise BadRequestException("Email already registered")

        new_user = User(
            username=user_in.username.strip(),
            email=user_in.email.strip(),
            full_name=user_in.full_name.strip(),
            hashed_password=get_password_hash(user_in.password.strip()),
            role=user_in.role,
            program=user_in.program,
            year_section=user_in.year_section,
            department_id=user_in.department_id,
        )
        return self.user_repo.create(new_user)
