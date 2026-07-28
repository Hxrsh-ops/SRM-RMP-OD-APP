from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from ....core.database import get_db
from ....repositories.user_repository import UserRepository
from ....services.auth_service import AuthService
from ....schemas.token import Token
from ....schemas.user import UserResponse, LoginRequest
from ...dependencies import get_current_user
from ....models.user import User

router = APIRouter()

@router.post("/login", response_model=Token)
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    auth_service = AuthService(user_repo)
    login_req = LoginRequest(username=form_data.username, password=form_data.password)
    token, _ = auth_service.login(login_req)
    return token

@router.post("/login/json", response_model=dict)
def login_json(
    login_req: LoginRequest,
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    auth_service = AuthService(user_repo)
    token, user = auth_service.login(login_req)
    return {
        "access_token": token.access_token,
        "refresh_token": token.refresh_token,
        "token_type": "bearer",
        "user": UserResponse.model_validate(user)
    }

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.post("/logout")
def logout(current_user: User = Depends(get_current_user)):
    return {"message": "Logged out successfully"}
