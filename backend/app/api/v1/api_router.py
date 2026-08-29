from fastapi import APIRouter
from .endpoints import auth, users, od_requests, attachments, notifications, admin, class_sections

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(class_sections.router, prefix="/class-sections", tags=["Class Sections"])
api_router.include_router(od_requests.router, prefix="/od-requests", tags=["OD Requests"])
api_router.include_router(attachments.router, prefix="/attachments", tags=["Attachments"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(admin.router, prefix="/admin", tags=["Super Admin"])
