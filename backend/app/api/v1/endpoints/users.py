from fastapi import APIRouter, Depends
from ....schemas.user import UserResponse
from ...dependencies import get_current_user
from ....models.user import User

router = APIRouter()

@router.get("/profile", response_model=UserResponse)
def get_user_profile(current_user: User = Depends(get_current_user)):
    return current_user
