import uuid
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, Query, status, Response, HTTPException

from sqlalchemy.orm import Session
from ....core.database import get_db
from ....core.exceptions import NotFoundException, BadRequestException, PermissionDeniedException
from ....repositories.user_repository import UserRepository
from ....repositories.od_request_repository import OdRequestRepository
from ....repositories.audit_log_repository import AuditLogRepository
from ....models.user import User
from ....models.department import Department
from ....models.enums import UserRole, OdStatus
from ...dependencies import require_roles, get_current_user
from ....services.admin_service import AdminService
from ....schemas.admin import (
    AdminDashboardMetricsResponse, UserResponseSchema, UserCreateSchema, UserUpdateSchema,
    UserStatusUpdateSchema, ResetPasswordSchema, BulkUserActionSchema, PaginatedUsersResponse,
    DepartmentResponseSchema, DepartmentCreateSchema, DepartmentUpdateSchema,
    FacultyWorkloadSchema, FacultyTransferSchema, OrganizationSettingsSchema,
    AuditLogResponseSchema, PaginatedAuditLogsResponse, SystemHealthResponseSchema,
    SecurityCenterSummaryResponse, AnalyticsSummarySchema, AssignFacultyRequestSchema
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

def _build_admin_user_response(user: User, db: Session) -> Dict[str, Any]:
    dept_name = None
    if user.department_id:
        dept = db.query(Department).filter(Department.id == user.department_id).first()
        dept_name = dept.name if dept else None

    fac_name = None
    if user.assigned_faculty_id:
        fac = db.query(User).filter(User.id == user.assigned_faculty_id).first()
        fac_name = fac.full_name if fac else None

    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role,
        "department_id": user.department_id,
        "department_name": dept_name,
        "program": user.program,
        "year_section": user.year_section,
        "assigned_faculty_id": user.assigned_faculty_id,
        "assigned_faculty_name": fac_name,
        "is_active": user.is_active,
        "is_locked": getattr(user, "is_locked", False),
        "force_password_change": getattr(user, "force_password_change", False),
        "failed_login_attempts": getattr(user, "failed_login_attempts", 0),
        "last_login_at": getattr(user, "last_login_at", None),
        "created_at": user.created_at,
    }

@router.post("/users", response_model=UserResponseSchema, status_code=status.HTTP_201_CREATED, dependencies=[Depends(admin_only)])
def create_user(
    data: UserCreateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    user = service.create_user(data, current_user.id)
    return _build_admin_user_response(user, db)

@router.put("/users/{user_id}", response_model=UserResponseSchema, dependencies=[Depends(admin_only)])
def update_user(
    user_id: uuid.UUID,
    data: UserUpdateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    user = service.update_user(user_id, data, current_user.id)
    return _build_admin_user_response(user, db)

@router.patch("/users/{user_id}/status", response_model=UserResponseSchema, dependencies=[Depends(admin_only)])
def update_user_status(
    user_id: uuid.UUID,
    data: UserStatusUpdateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    user = service.set_user_status(user_id, data.is_active, data.is_locked, current_user.id)
    return _build_admin_user_response(user, db)

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

@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(admin_only)])
def delete_user(
    user_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    service.delete_user(user_id, current_user.id)
    return None

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
@router.get("/settings", response_model=OrganizationSettingsSchema)
def get_organization_settings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
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

# -----------------------------------------------------------------------------
# 9. Analytics & PDF Export
# -----------------------------------------------------------------------------
@router.get("/analytics", dependencies=[Depends(admin_only)])
def get_analytics_summary(db: Session = Depends(get_db)):
    service = AdminService(db)
    return service.get_analytics_summary()

@router.get("/reports/pdf", dependencies=[Depends(admin_only)])
def export_executive_pdf_report(db: Session = Depends(get_db)):
    service = AdminService(db)
    pdf_bytes = service.generate_executive_pdf_report()
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=Executive_OD_Report.pdf"}
    )

# -----------------------------------------------------------------------------
# 10. Student-Faculty Assignment Routes
# -----------------------------------------------------------------------------
@router.get("/students/{student_id}/available-faculty", response_model=List[UserResponseSchema], dependencies=[Depends(admin_only)])
def get_available_faculty_for_student(
    student_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    faculty_list = service.get_available_faculty_for_student(student_id)
    return [_build_admin_user_response(f, db) for f in faculty_list]

@router.put("/students/{student_id}/assign-faculty", response_model=UserResponseSchema, dependencies=[Depends(admin_only)])
def assign_faculty_to_student(
    student_id: uuid.UUID,
    data: AssignFacultyRequestSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    student = service.assign_faculty_to_student(student_id, data.faculty_id, current_user.id)
    return _build_admin_user_response(student, db)

@router.delete("/students/{student_id}/assign-faculty", response_model=UserResponseSchema, dependencies=[Depends(admin_only)])
def unassign_faculty_from_student(
    student_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    student = service.unassign_faculty_from_student(student_id, current_user.id)
    return _build_admin_user_response(student, db)

@router.get("/faculty/{faculty_id}/students", response_model=List[UserResponseSchema], dependencies=[Depends(admin_only)])
def get_students_for_faculty(
    faculty_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    service = AdminService(db)
    students = service.get_students_for_faculty(faculty_id)
    return [_build_admin_user_response(s, db) for s in students]

# -----------------------------------------------------------------------------
# 11. User Profile & Associated Records Inspection / Record Deletion
# -----------------------------------------------------------------------------
@router.get("/users/{user_id}/records", dependencies=[Depends(admin_only)])
def get_user_profile_and_records(
    user_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    od_repo = OdRequestRepository(db)
    user = user_repo.get_by_id(user_id)
    if not user:
        raise NotFoundException("User not found")

    from .od_requests import _build_od_response, _get_student_dept, _is_escalated_to_hod, _is_escalated_to_dean
    from ....models.system_setting import SystemSetting

    setting = db.query(SystemSetting).filter(SystemSetting.key == "org_settings").first()
    policy = {}
    if setting and setting.value and isinstance(setting.value, dict):
        policy = setting.value
    workflow_mode = policy.get("workflow_mode", "STANDARD")
    evidence_mode = policy.get("evidence_workflow_mode", "FA_ONLY")

    def _user_acted_on(r, u):
        for ev in (r.timeline or []):
            if ev.actor_name and (u.full_name in ev.actor_name or u.username in ev.actor_name):
                return True
        for c in (r.comments or []):
            if c.author_name and (u.full_name in c.author_name or u.username in c.author_name):
                return True
        return False

    user_info = UserResponseSchema.model_validate(_build_admin_user_response(user, db)).model_dump(mode="json")
    if user.role == UserRole.STUDENT:
        requests = od_repo.list_by_student(user.id)
    elif user.role == UserRole.FACULTY_ADVISOR:
        all_fa_reqs = od_repo.list_by_faculty_assigned(user.id)
        # Active in-flight records only: vanish after full completion or rejection to avoid pile-up
        requests = [r for r in all_fa_reqs if r.status not in (OdStatus.COMPLETED, OdStatus.REJECTED, OdStatus.FACULTY_REJECTED)]
    elif user.role == UserRole.COORDINATOR:
        all_reqs = od_repo.list_all()
        if user.department_id:
            target_dept = str(user.department_id)
            dept_reqs = [r for r in all_reqs if _get_student_dept(r, user_repo) == target_dept]
        else:
            dept_reqs = all_reqs

        if workflow_mode == "DIRECT_HOD":
            requests = []
        else:
            filtered = []
            for r in dept_reqs:
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED] and not _is_escalated_to_hod(r) and not _is_escalated_to_dean(r):
                    filtered.append(r)
                elif r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR and evidence_mode in ["FA_COORDINATOR", "FA_COORDINATOR_HOD"] and not _is_escalated_to_dean(r):
                    filtered.append(r)
            requests = filtered

    elif user.role == UserRole.HOD:
        all_reqs = od_repo.list_all()
        if user.department_id:
            target_dept = str(user.department_id)
            dept_reqs = [r for r in all_reqs if _get_student_dept(r, user_repo) == target_dept]
        else:
            dept_reqs = all_reqs

        filtered = []
        for r in dept_reqs:
            if workflow_mode == "DIRECT_HOD":
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED] and not _is_escalated_to_dean(r):
                    filtered.append(r)
                elif r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR and (evidence_mode in ["FA_HOD", "FA_COORDINATOR_HOD"] or _is_escalated_to_hod(r)) and not _is_escalated_to_dean(r):
                    filtered.append(r)
            else: # STANDARD or COMPREHENSIVE
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED] and _is_escalated_to_hod(r) and not _is_escalated_to_dean(r):
                    filtered.append(r)
                elif r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR and (evidence_mode in ["FA_HOD", "FA_COORDINATOR_HOD"] or _is_escalated_to_hod(r)) and not _is_escalated_to_dean(r):
                    filtered.append(r)
        requests = filtered

    elif user.role == UserRole.DEAN:
        all_reqs = od_repo.list_all()
        requests = [r for r in all_reqs if _is_escalated_to_dean(r) and r.status not in (OdStatus.COMPLETED, OdStatus.REJECTED, OdStatus.FACULTY_REJECTED)]
    elif user.role == UserRole.MASTER_ADMIN:
        requests = []
    else:
        requests = od_repo.list_all()

    serialized_reqs = [_build_od_response(r, user_repo).model_dump(mode="json") for r in requests]

    return {
        "user": user_info,
        "records": serialized_reqs,
        "total_records": len(serialized_reqs),
    }

@router.delete("/od-requests/{request_id}", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_only)])
def admin_delete_od_request(
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    od_repo = OdRequestRepository(db)
    req = od_repo.get_by_id(request_id)
    if not req:
        raise NotFoundException(f"OD Request {request_id} not found")

    success = od_repo.hard_delete(request_id)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to delete OD request")

    audit_repo = AuditLogRepository(db)
    audit_repo.log(
        actor_id=current_user.id,
        action="OD_REQUEST_DELETED",
        resource_type="OD_REQUEST",
        resource_id=request_id,
        request_id=request_id,
        details={
            "deleted_request_id": request_id,
            "actor_name": current_user.full_name,
            "actor_role": "MASTER_ADMIN"
        }
    )
    return {"message": f"OD Request {request_id} deleted permanently by Master Admin"}

@router.delete("/users/{user_id}/od-requests", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_only)])
def admin_delete_all_user_od_requests(
    user_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    user = user_repo.get_by_id(user_id)
    if not user:
        raise NotFoundException("User not found")

    od_repo = OdRequestRepository(db)
    deleted_count = od_repo.hard_delete_all_by_user(user.id, user.role)

    audit_repo = AuditLogRepository(db)
    audit_repo.log(
        actor_id=current_user.id,
        action="ALL_USER_OD_REQUESTS_DELETED",
        resource_type="USER",
        resource_id=str(user_id),
        details={
            "user_username": user.username,
            "deleted_count": deleted_count,
            "actor_name": current_user.full_name,
            "actor_role": "MASTER_ADMIN"
        }
    )
    return {"message": f"Successfully deleted {deleted_count} OD request(s) for user {user.username}", "deleted_count": deleted_count}

# -----------------------------------------------------------------------------
# 12. Security Center Event Purge
# -----------------------------------------------------------------------------
@router.delete("/security/events/{event_id}", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_only)])
def delete_security_event(
    event_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from ....models.security_event import SecurityEvent
    evt = db.query(SecurityEvent).filter(SecurityEvent.id == event_id).first()
    if not evt:
        raise NotFoundException("Security event not found")
    db.delete(evt)
    db.commit()
    return {"message": "Security event deleted"}

@router.delete("/security/events", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_only)])
def clear_all_security_events(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from ....models.security_event import SecurityEvent
    deleted_count = db.query(SecurityEvent).delete()
    db.commit()
    return {"message": f"Cleared {deleted_count} security event log(s)"}
