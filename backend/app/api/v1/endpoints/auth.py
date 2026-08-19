import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from ....core.config import settings
from ....core.database import get_db
from ....core.security import create_access_token, create_refresh_token
from ....repositories.user_repository import UserRepository
from ....services.auth_service import AuthService
from ....schemas.token import Token, RefreshTokenRequest
from ....schemas.user import UserResponse, LoginRequest, ChangePasswordRequest
from ...dependencies import get_current_user
from ....models.user import User

router = APIRouter()

def _build_user_response(user: User) -> UserResponse:
    resp = UserResponse.model_validate(user)
    if user.assigned_faculty:
        resp.assigned_faculty_name = user.assigned_faculty.full_name
    return resp

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
        "user": _build_user_response(user)
    }

@router.post("/refresh", response_model=Token)
def refresh_token(
    refresh_req: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    try:
        payload = jwt.decode(refresh_req.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Expired or invalid refresh token")

    user_repo = UserRepository(db)
    user = user_repo.get_by_id(user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User inactive or not found")

    new_access_token = create_access_token(subject=user.id, role=user.role.value)
    new_refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer"
    )

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return _build_user_response(current_user)

@router.post("/change-password")
def change_password(
    req: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from ....core.security import verify_password, get_password_hash
    if not verify_password(req.current_password, current_user.hashed_password):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Current password is incorrect")
    
    current_user.hashed_password = get_password_hash(req.new_password)
    current_user.force_password_change = False
    db.commit()
    db.refresh(current_user)
    return {"message": "Password changed successfully"}

@router.post("/logout")
def logout(current_user: User = Depends(get_current_user)):
    return {"message": "Logged out successfully"}
