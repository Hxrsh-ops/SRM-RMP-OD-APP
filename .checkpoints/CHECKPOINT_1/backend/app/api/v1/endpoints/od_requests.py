import csv
import io
from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, status, UploadFile, File, Form, HTTPException, Query
from fastapi.responses import Response
from sqlalchemy.orm import Session
from ....core.database import get_db
from ....core.exceptions import NotFoundException, PermissionDeniedException, BadRequestException
from ....repositories.user_repository import UserRepository
from ....repositories.od_request_repository import OdRequestRepository
from ....repositories.notification_repository import NotificationRepository
from ....services.notification_service import NotificationService
from ....services.workflow_service import WorkflowService
from ....services.storage_service import LocalStorageProvider
from ....schemas.od_request import (
    OdRequestCreate,
    OdRequestResponse,
    FacultyActionRequest,
    CoordinatorActionRequest,
    CoordinatorAnalyticsResponse,
)
from ....models.user import User
from ....models.enums import UserRole, OdStatus
from ....models.od_request import OdRequest
from ...dependencies import get_current_user, require_roles

router = APIRouter()

def get_workflow_service(db: Session = Depends(get_db)) -> WorkflowService:
    od_repo = OdRequestRepository(db)
    user_repo = UserRepository(db)
    noti_repo = NotificationRepository(db)
    noti_service = NotificationService(noti_repo)
    return WorkflowService(od_repo, user_repo, noti_service)

def _build_od_response(req: OdRequest, user_repo: UserRepository) -> OdRequestResponse:
    resp = OdRequestResponse.model_validate(req)
    if req.student:
        resp.student_name = req.student.full_name
        resp.register_number = req.student.username
        resp.program = req.student.program
        resp.year_section = req.student.year_section
        resp.student_email = req.student.email
    elif req.student_id:
        st = user_repo.get_by_id(req.student_id)
        if st:
            resp.student_name = st.full_name
            resp.register_number = st.username
            resp.program = st.program
            resp.year_section = st.year_section
            resp.student_email = st.email

    if req.faculty:
        resp.faculty_advisor_name = req.faculty.full_name
    elif req.faculty_id:
        fa = user_repo.get_by_id(req.faculty_id)
        if fa:
            resp.faculty_advisor_name = fa.full_name

    # Evidence Overdue & Days Calculation
    if req.status == OdStatus.APPROVED_AWAITING_EVIDENCE:
        today = date.today()
        if today > req.end_date:
            resp.is_evidence_overdue = True
            resp.days_past_event = (today - req.end_date).days
        else:
            resp.is_evidence_overdue = False
            resp.days_past_event = 0
    else:
        resp.is_evidence_overdue = False
        resp.days_past_event = 0

    return resp

def _get_student_dept(req: OdRequest, user_repo: UserRepository) -> Optional[str]:
    if req.student and req.student.department_id:
        return str(req.student.department_id)
    if req.student_id:
        st = user_repo.get_by_id(req.student_id)
        if st and st.department_id:
            return str(st.department_id)
    return None

def _is_escalated_to_dean(req: OdRequest) -> bool:
    for event in (req.timeline or []):
        t_low = (event.title or "").lower()
        n_low = (event.note or "").lower()
        if "escalated to dean" in t_low or "[escalated to dean]" in n_low:
            return True
    return False

def _is_escalated_to_hod(req: OdRequest) -> bool:
    for event in (req.timeline or []):
        t_low = (event.title or "").lower()
        n_low = (event.note or "").lower()
        if "escalated to head of department" in t_low or "escalated to hod" in t_low or "[escalated to hod]" in n_low:
            return True
    return False

@router.get("", response_model=List[OdRequestResponse])
def list_od_requests(
    include_history: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from ....models.system_setting import SystemSetting
    od_repo = OdRequestRepository(db)
    user_repo = UserRepository(db)

    setting = db.query(SystemSetting).filter(SystemSetting.key == "org_settings").first()
    policy = {}
    if setting and setting.value:
        policy = setting.value if isinstance(setting.value, dict) else {}
    workflow_mode = policy.get("workflow_mode", "STANDARD")
    evidence_mode = policy.get("evidence_workflow_mode", "FA_ONLY")

    if current_user.role == UserRole.STUDENT:
        requests = od_repo.list_by_student(current_user.id)

    elif current_user.role == UserRole.FACULTY_ADVISOR:
        requests = od_repo.list_faculty_all(current_user.id) if include_history else od_repo.list_faculty_pending(current_user.id)

    elif current_user.role == UserRole.COORDINATOR:
        all_reqs = od_repo.list_all()
        if current_user.department_id:
            target_dept = str(current_user.department_id)
            all_reqs = [r for r in all_reqs if _get_student_dept(r, user_repo) == target_dept]

        if include_history:
            requests = all_reqs
        else:
            filtered = []
            for r in all_reqs:
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]:
                    if workflow_mode == "DIRECT_HOD":
                        # In Direct HOD mode, Coordinator is bypassed for initial approvals
                        continue
                    elif workflow_mode == "COMPREHENSIVE":
                        if not _is_escalated_to_hod(r) and not _is_escalated_to_dean(r):
                            filtered.append(r)
                    else: # STANDARD
                        if not _is_escalated_to_hod(r) and not _is_escalated_to_dean(r):
                            filtered.append(r)
                elif r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR:
                    if evidence_mode in ["FA_COORDINATOR", "FA_COORDINATOR_HOD"] and not _is_escalated_to_dean(r):
                        filtered.append(r)
            requests = filtered

    elif current_user.role == UserRole.HOD:
        all_reqs = od_repo.list_all()
        if current_user.department_id:
            target_dept = str(current_user.department_id)
            all_reqs = [r for r in all_reqs if _get_student_dept(r, user_repo) == target_dept]

        if include_history:
            requests = all_reqs
        else:
            filtered = []
            for r in all_reqs:
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]:
                    if _is_escalated_to_dean(r):
                        continue
                    if workflow_mode == "DIRECT_HOD":
                        filtered.append(r)
                    elif workflow_mode in ["COMPREHENSIVE", "STANDARD"]:
                        if _is_escalated_to_hod(r):
                            filtered.append(r)
                elif r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR:
                    if _is_escalated_to_dean(r):
                        continue
                    if evidence_mode in ["FA_HOD", "FA_COORDINATOR_HOD"] or _is_escalated_to_hod(r):
                        filtered.append(r)
            requests = filtered

    elif current_user.role == UserRole.DEAN:
        all_reqs = od_repo.list_all()
        if include_history:
            requests = all_reqs
        else:
            filtered = []
            for r in all_reqs:
                if _is_escalated_to_dean(r):
                    if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED, OdStatus.PENDING_EVIDENCE_COORDINATOR]:
                        filtered.append(r)
            requests = filtered

    else: # MASTER_ADMIN
        if include_history:
            requests = od_repo.list_all()
        else:
            requests = [
                r for r in od_repo.list_all()
                if r.status in [
                    OdStatus.PENDING_FACULTY,
                    OdStatus.SUBMITTED,
                    OdStatus.PENDING_COORDINATOR,
                    OdStatus.FACULTY_APPROVED,
                    OdStatus.PENDING_EVIDENCE_FACULTY,
                    OdStatus.PENDING_EVIDENCE_COORDINATOR
                ]
            ]

    return [_build_od_response(req, user_repo) for req in requests]

@router.get("/analytics/coordinator", response_model=CoordinatorAnalyticsResponse)
def get_coordinator_analytics(
    current_user: User = Depends(require_roles([UserRole.COORDINATOR, UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.DEAN])),
    workflow_service: WorkflowService = Depends(get_workflow_service),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    od_repo = OdRequestRepository(db)
    all_reqs = od_repo.list_all()

    from ....models.system_setting import SystemSetting
    setting = db.query(SystemSetting).filter(SystemSetting.key == "org_settings").first()
    sys_settings = setting.value if (setting and setting.value) else {}
    workflow_mode = sys_settings.get("workflow_hierarchy_mode", "DIRECT_HOD")
    evidence_mode = sys_settings.get("evidence_approval_mode", "FA_HOD")

    # Scope to department if Coordinator or HOD
    if current_user.department_id and current_user.role in [UserRole.COORDINATOR, UserRole.HOD]:
        target_dept = str(current_user.department_id)
        dept_reqs = [r for r in all_reqs if _get_student_dept(r, user_repo) == target_dept]
    else:
        dept_reqs = all_reqs

    # Compute status counts for department
    counts = {}
    for r in dept_reqs:
        s = r.status.value if hasattr(r.status, 'value') else str(r.status)
        counts[s.upper()] = counts.get(s.upper(), 0) + 1

    # In Direct HOD mode, Coordinator has 0 pending items
    if current_user.role == UserRole.COORDINATOR and workflow_mode == "DIRECT_HOD":
        pending_coord = 0
        pending_evidence_coord = 0 if evidence_mode == "FA_HOD" else counts.get('PENDING_EVIDENCE_COORDINATOR', 0)
    elif current_user.role == UserRole.COORDINATOR:
        pending_coord = counts.get('PENDING_COORDINATOR', 0) + counts.get('FACULTY_APPROVED', 0)
        pending_evidence_coord = counts.get('PENDING_EVIDENCE_COORDINATOR', 0) if evidence_mode in ["FA_COORDINATOR", "FA_COORDINATOR_HOD"] else 0
    elif current_user.role == UserRole.HOD:
        pending_coord = counts.get('PENDING_COORDINATOR', 0) + counts.get('FACULTY_APPROVED', 0)
        pending_evidence_coord = counts.get('PENDING_EVIDENCE_COORDINATOR', 0)
    elif current_user.role == UserRole.DEAN:
        pending_coord = sum(1 for r in all_reqs if _is_escalated_to_dean(r) and r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED])
        pending_evidence_coord = sum(1 for r in all_reqs if _is_escalated_to_dean(r) and r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR)
    else:
        pending_coord = counts.get('PENDING_COORDINATOR', 0) + counts.get('FACULTY_APPROVED', 0)
        pending_evidence_coord = counts.get('PENDING_EVIDENCE_COORDINATOR', 0)

    approved_awaiting = counts.get('APPROVED_AWAITING_EVIDENCE', 0)
    completed = counts.get('COMPLETED', 0)
    total = len(dept_reqs)

    return CoordinatorAnalyticsResponse(
        pending_coordinator_count=pending_coord,
        approved_awaiting_evidence_count=approved_awaiting,
        pending_evidence_coordinator_count=pending_evidence_coord,
        completed_count=completed,
        total_submissions_count=total,
    )

@router.post("", response_model=OdRequestResponse, status_code=status.HTTP_201_CREATED)
def create_od_request(
    req_in: OdRequestCreate,
    current_user: User = Depends(require_roles([UserRole.STUDENT])),
    workflow_service: WorkflowService = Depends(get_workflow_service),
    db: Session = Depends(get_db)
):
    saved_req = workflow_service.create_od_request(current_user.id, req_in)
    user_repo = UserRepository(db)
    return _build_od_response(saved_req, user_repo)

@router.get("/{request_id}", response_model=OdRequestResponse)
def get_od_request_by_id(
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    od_repo = OdRequestRepository(db)
    user_repo = UserRepository(db)
    req = od_repo.get_by_id(request_id)
    if not req:
        raise NotFoundException("OD Request not found")

    # Object-level authorization check
    if current_user.role == UserRole.STUDENT and req.student_id != current_user.id:
        raise PermissionDeniedException("You are not authorized to view another student's OD request")

    if current_user.role == UserRole.FACULTY_ADVISOR:
        is_assigned = (req.faculty_id == current_user.id) or (req.student and req.student.assigned_faculty_id == current_user.id)
        if not is_assigned:
            raise PermissionDeniedException("You are not authorized to view this OD request")

    if current_user.role == UserRole.COORDINATOR:
        if current_user.department_id and req.student and req.student.department_id != current_user.department_id:
            raise PermissionDeniedException("You are not authorized to view requests outside your department")

    return _build_od_response(req, user_repo)

@router.post("/{request_id}/faculty-action", response_model=OdRequestResponse)
def faculty_action(
    request_id: str,
    action: FacultyActionRequest,
    current_user: User = Depends(require_roles([UserRole.FACULTY_ADVISOR])),
    workflow_service: WorkflowService = Depends(get_workflow_service),
    db: Session = Depends(get_db)
):
    updated_req = workflow_service.process_faculty_action(request_id, current_user.id, action)
    user_repo = UserRepository(db)
    return _build_od_response(updated_req, user_repo)

@router.post("/{request_id}/coordinator-action", response_model=OdRequestResponse)
def coordinator_action(
    request_id: str,
    action: CoordinatorActionRequest,
    current_user: User = Depends(require_roles([UserRole.COORDINATOR, UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.DEAN])),
    workflow_service: WorkflowService = Depends(get_workflow_service),
    db: Session = Depends(get_db)
):
    updated_req = workflow_service.process_coordinator_action(request_id, current_user.id, action)
    user_repo = UserRepository(db)
    return _build_od_response(updated_req, user_repo)

@router.post("/{request_id}/completion-evidence", response_model=OdRequestResponse)
async def submit_completion_evidence(
    request_id: str,
    completion_summary: str = Form(...),
    files: List[UploadFile] = File(...),
    current_user: User = Depends(require_roles([UserRole.STUDENT])),
    workflow_service: WorkflowService = Depends(get_workflow_service),
    db: Session = Depends(get_db)
):
    storage = LocalStorageProvider()
    attachments_info = []

    for file in files:
        meta = await storage.upload_file(file=file, uploaded_by=current_user.full_name, document_category="completion_evidence")
        attachments_info.append(meta)

    updated_req = workflow_service.submit_completion_evidence(
        request_id=request_id,
        student_user_id=current_user.id,
        completion_summary=completion_summary,
        attachments_info=attachments_info
    )

    user_repo = UserRepository(db)
    return _build_od_response(updated_req, user_repo)

@router.get("/department/export-csv", dependencies=[Depends(require_roles([UserRole.COORDINATOR, UserRole.HOD, UserRole.DEAN, UserRole.MASTER_ADMIN, UserRole.FACULTY_ADVISOR]))])
def export_department_od_csv(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    od_repo = OdRequestRepository(db)
    user_repo = UserRepository(db)
    all_reqs = od_repo.list_all()

    if current_user.role in [UserRole.COORDINATOR, UserRole.HOD] and current_user.department_id:
        target_dept = str(current_user.department_id)
        reqs = [r for r in all_reqs if _get_student_dept(r, user_repo) == target_dept]
    elif current_user.role == UserRole.FACULTY_ADVISOR:
        reqs = [r for r in all_reqs if r.faculty_id == current_user.id]
    else:
        reqs = all_reqs

    output = io.StringIO()
    output.write('\ufeff')  # UTF-8 BOM for Excel
    writer = csv.writer(output)
    writer.writerow([
        "OD Request ID",
        "Student Register Number",
        "Student Full Name",
        "Program",
        "Year & Section",
        "Student Email",
        "Event Reason",
        "Event Purpose",
        "Start Date",
        "End Date",
        "Duration (Days)",
        "Venue",
        "Organizer",
        "Assigned Faculty Advisor",
        "Current Status",
        "Completion Evidence Status",
        "Submission Timestamp"
    ])

    for r in reqs:
        resp = _build_od_response(r, user_repo)
        status_label = r.status.value if hasattr(r.status, 'value') else str(r.status)
        evidence_status = "Not Required / In-Flight"
        if r.status == OdStatus.APPROVED_AWAITING_EVIDENCE:
            evidence_status = f"Overdue by {resp.days_past_event} days" if resp.is_evidence_overdue else "Awaiting Student Upload"
        elif r.status == OdStatus.PENDING_EVIDENCE_FACULTY:
            evidence_status = "Pending FA Verification"
        elif r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR:
            evidence_status = "Pending Dept/HOD Verification"
        elif r.status == OdStatus.COMPLETED:
            evidence_status = "Verified & Granted"

        writer.writerow([
            r.id,
            resp.register_number or "",
            resp.student_name or "",
            resp.program or "",
            resp.year_section or "",
            resp.student_email or "",
            r.reason,
            r.purpose,
            str(r.start_date),
            str(r.end_date),
            r.duration_days,
            r.venue or "",
            r.organizer or "",
            resp.faculty_advisor_name or "",
            status_label,
            evidence_status,
            r.created_at.strftime("%Y-%m-%d %H:%M") if r.created_at else ""
        ])

    csv_data = output.getvalue()
    filename = f"department_od_report_{date.today().isoformat()}.csv"
    return Response(
        content=csv_data,
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"'
        }
    )
