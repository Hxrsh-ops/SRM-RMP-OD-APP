import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from ....core.database import get_db
from ....models.user import User
from ....models.enums import UserRole
from ...dependencies import require_roles, get_current_user
from ....services.admin_service import AdminService
from ....schemas.admin import (
    AdminDashboardMetricsResponse, UserResponseSchema, UserCreateSchema, UserUpdateSchema,
    UserStatusUpdateSchema, ResetPasswordSchema, BulkUserActionSchema, PaginatedUsersResponse,
    DepartmentResponseSchema, DepartmentCreateSchema, DepartmentUpdateSchema,
    FacultyWorkloadSchema, FacultyTransferSchema, OrganizationSettingsSchema,
    AuditLogResponseSchema, PaginatedAuditLogsResponse, SystemHealthResponseSchema,
    SecurityCenterSummaryResponse, AnalyticsSummarySchema
)

router = APIRouter()
admin_only = require_roles([UserRole.MASTER_ADMIN])

# -----------------------------------------------------------------------------
# 1. Executive Dashboard
# -----------------------------------------------------------------------------
@router.get("/dashboard/metrics", response_model=AdminDashboardMetricsResponse, dependencies=[Depends(admin_only)])
def get_dashboard_metrics(db: Session = Depends(get_db)):
    service = AdminService(db)
    return service.get_dashboard_metrics()

# -----------------------------------------------------------------------------
# 2. User Management
# -----------------------------------------------------------------------------
@router.get("/users", response_model=PaginatedUsersResponse, dependencies=[Depends(admin_only)])
def get_users(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    query: Optional[str] = None,
    role: Optional[UserRole] = None,
    department_id: Optional[uuid.UUID] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    items, total = service.get_users(page, limit, query, role, department_id, is_active)
    total_pages = (total + limit - 1) // limit if limit > 0 else 1
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": total_pages
    }

@router.post("/users", response_model=UserResponseSchema, status_code=status.HTTP_201_CREATED, dependencies=[Depends(admin_only)])
def create_user(
    data: UserCreateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    user = service.create_user(data, current_user.id)
    return user

@router.put("/users/{user_id}", response_model=UserResponseSchema, dependencies=[Depends(admin_only)])
def update_user(
    user_id: uuid.UUID,
    data: UserUpdateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    return service.update_user(user_id, data, current_user.id)

@router.patch("/users/{user_id}/status", response_model=UserResponseSchema, dependencies=[Depends(admin_only)])
def update_user_status(
    user_id: uuid.UUID,
    data: UserStatusUpdateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    return service.set_user_status(user_id, data.is_active, data.is_locked, current_user.id)

@router.post("/users/{user_id}/reset-password", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_only)])
def reset_user_password(
    user_id: uuid.UUID,
    data: ResetPasswordSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    service.reset_user_password(user_id, data.new_password, current_user.id)
    return {"message": "Password reset successfully"}

@router.post("/users/bulk", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_only)])
def bulk_user_action(
    data: BulkUserActionSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    count = service.bulk_user_action(data, current_user.id)
    return {"message": f"Successfully performed '{data.action}' on {count} users"}

# -----------------------------------------------------------------------------
# 3. Department Management
# -----------------------------------------------------------------------------
@router.get("/departments", response_model=List[DepartmentResponseSchema], dependencies=[Depends(admin_only)])
def get_departments(db: Session = Depends(get_db)):
    service = AdminService(db)
    return service.get_departments()

@router.post("/departments", response_model=DepartmentResponseSchema, status_code=status.HTTP_201_CREATED, dependencies=[Depends(admin_only)])
def create_department(
    data: DepartmentCreateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    return service.create_department(data, current_user.id)

@router.put("/departments/{dept_id}", response_model=DepartmentResponseSchema, dependencies=[Depends(admin_only)])
def update_department(
    dept_id: uuid.UUID,
    data: DepartmentUpdateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    return service.update_department(dept_id, data, current_user.id)

# -----------------------------------------------------------------------------
# 4. Faculty Administration
# -----------------------------------------------------------------------------
@router.get("/faculty", response_model=List[FacultyWorkloadSchema], dependencies=[Depends(admin_only)])
def get_faculty_workload(db: Session = Depends(get_db)):
    service = AdminService(db)
    return service.get_faculty_workload()

@router.post("/faculty/transfer", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_only)])
def transfer_faculty_students(
    data: FacultyTransferSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    count = service.transfer_faculty_students(data.source_faculty_id, data.target_faculty_id, data.student_ids, current_user.id)
    return {"message": f"Successfully transferred {count} students"}

# -----------------------------------------------------------------------------
# 5. Organization Settings
# -----------------------------------------------------------------------------
@router.get("/settings", response_model=OrganizationSettingsSchema, dependencies=[Depends(admin_only)])
def get_organization_settings(db: Session = Depends(get_db)):
    service = AdminService(db)
    return service.get_organization_settings()

@router.put("/settings", response_model=OrganizationSettingsSchema, dependencies=[Depends(admin_only)])
def update_organization_settings(
    data: OrganizationSettingsSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    return service.update_organization_settings(data, current_user.id)

# -----------------------------------------------------------------------------
# 6. Audit Logs
# -----------------------------------------------------------------------------
@router.get("/audit-logs", response_model=PaginatedAuditLogsResponse, dependencies=[Depends(admin_only)])
def get_audit_logs(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    action: Optional[str] = None,
    resource_type: Optional[str] = None,
    actor_id: Optional[uuid.UUID] = None,
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    items, total = service.get_audit_logs(page, limit, action, resource_type, actor_id)
    total_pages = (total + limit - 1) // limit if limit > 0 else 1
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": total_pages
    }

# -----------------------------------------------------------------------------
# 7. System Monitoring
# -----------------------------------------------------------------------------
@router.get("/monitoring", response_model=SystemHealthResponseSchema, dependencies=[Depends(admin_only)])
def get_system_monitoring(db: Session = Depends(get_db)):
    service = AdminService(db)
    return service.get_system_monitoring()

# -----------------------------------------------------------------------------
# 8. Security Center
# -----------------------------------------------------------------------------
@router.get("/security/summary", response_model=SecurityCenterSummaryResponse, dependencies=[Depends(admin_only)])
def get_security_center_summary(db: Session = Depends(get_db)):
    service = AdminService(db)
    return service.get_security_center_summary()
