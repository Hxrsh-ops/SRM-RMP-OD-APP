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
from ....schemas.shared_clearance import ShareClearanceRequest, SharedClearanceResponse
from ....models.user import User
from ....models.enums import UserRole, OdStatus
from ....models.od_request import OdRequest
from ....models.shared_clearance import SharedOdClearance, ClearanceShareStatus
from ....models.system_setting import SystemSetting
from ...dependencies import get_current_user, require_roles
from datetime import datetime, timezone

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
        if "escalated to dean" in t_low or "escalated to executive dean" in t_low or "[escalated to dean]" in n_low:
            return True
    return False

def _is_escalated_to_hod(req: OdRequest) -> bool:
    for event in (req.timeline or []):
        t_low = (event.title or "").lower()
        n_low = (event.note or "").lower()
        if (
            "escalated to head of department" in t_low
            or "escalated to hod" in t_low
            or "[escalated to hod]" in n_low
            or "routed to hod" in t_low
            or "routed to head of department" in t_low
        ):
            return True
    return False

def _is_direct_hod_submission(req: OdRequest) -> bool:
    for event in (req.timeline or []):
        t_low = (event.title or "").lower()
        n_low = (event.note or "").lower()
        if (
            "directly for head of department" in t_low
            or "direct hod" in t_low
            or "direct hod" in n_low
            or "forwarded for head of department review" in t_low
            or "forwarded for head of department" in t_low
            or "forwarded for hod review" in t_low
            or "forwarded for hod" in t_low
            or "routed directly for head of department" in n_low
            or "coordinator bypassed" in n_low
            or "hod review" in t_low
            or "hod review" in n_low
        ):
            return True
    return False

@router.get("", response_model=List[OdRequestResponse])
def list_od_requests(
    include_history: bool = Query(True),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    od_repo = OdRequestRepository(db)

    setting = db.query(SystemSetting).filter(SystemSetting.key == "org_settings").first()
    policy = setting.value if (setting and setting.value) else {}
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

        if workflow_mode == "DIRECT_HOD":
            requests = []
        else:
            all_reqs = [r for r in all_reqs if not _is_direct_hod_submission(r)]
            if include_history:
                requests = all_reqs
            else:
                filtered = []
                for r in all_reqs:
                    if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]:
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
                    if workflow_mode == "DIRECT_HOD" or _is_direct_hod_submission(r):
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

    setting = db.query(SystemSetting).filter(SystemSetting.key == "org_settings").first()
    sys_settings = setting.value if (setting and setting.value) else {}
    workflow_mode = sys_settings.get("workflow_mode") or sys_settings.get("workflow_hierarchy_mode", "STANDARD")
    evidence_mode = sys_settings.get("evidence_workflow_mode") or sys_settings.get("evidence_approval_mode", "FA_COORDINATOR")

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

    # Compute pending counts strictly scoped to active authority role and workflow policies
    if current_user.role == UserRole.COORDINATOR:
        if workflow_mode == "DIRECT_HOD":
            pending_coord = 0
        else:
            pending_coord = sum(
                1 for r in dept_reqs
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]
                and not _is_direct_hod_submission(r)
                and not _is_escalated_to_hod(r) and not _is_escalated_to_dean(r)
            )
        
        if evidence_mode in ["FA_COORDINATOR", "FA_COORDINATOR_HOD"]:
            pending_evidence_coord = sum(
                1 for r in dept_reqs
                if r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR
                and not _is_escalated_to_hod(r) and not _is_escalated_to_dean(r)
            )
        else:
            pending_evidence_coord = 0

    elif current_user.role == UserRole.HOD:
        if workflow_mode == "DIRECT_HOD":
            pending_coord = sum(
                1 for r in dept_reqs
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]
                and not _is_escalated_to_dean(r)
            )
        else:
            pending_coord = sum(
                1 for r in dept_reqs
                if r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]
                and (_is_direct_hod_submission(r) or _is_escalated_to_hod(r))
                and not _is_escalated_to_dean(r)
            )
        
        if evidence_mode in ["FA_HOD", "FA_COORDINATOR_HOD"]:
            pending_evidence_coord = sum(
                1 for r in dept_reqs
                if r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR
                and (evidence_mode == "FA_HOD" or _is_escalated_to_hod(r))
                and not _is_escalated_to_dean(r)
            )
        else:
            pending_evidence_coord = 0

    elif current_user.role == UserRole.DEAN:
        pending_coord = sum(
            1 for r in all_reqs
            if _is_escalated_to_dean(r) and r.status in [OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED]
        )
        pending_evidence_coord = sum(
            1 for r in all_reqs
            if _is_escalated_to_dean(r) and r.status == OdStatus.PENDING_EVIDENCE_COORDINATOR
        )
    else:
        pending_coord = counts.get('PENDING_COORDINATOR', 0) + counts.get('FACULTY_APPROVED', 0)
        pending_evidence_coord = counts.get('PENDING_EVIDENCE_COORDINATOR', 0)

    if current_user.role == UserRole.COORDINATOR:
        if workflow_mode == "DIRECT_HOD":
            approved_awaiting = 0
            completed = 0
            total = 0
        else:
            coord_reqs = [r for r in dept_reqs if not _is_direct_hod_submission(r)]
            approved_awaiting = sum(
                1 for r in coord_reqs
                if r.status == OdStatus.APPROVED_AWAITING_EVIDENCE
                and not _is_escalated_to_dean(r)
            )
            completed = sum(1 for r in coord_reqs if r.status == OdStatus.COMPLETED)
            total = len(coord_reqs)
    elif current_user.role == UserRole.HOD:
        approved_awaiting = sum(
            1 for r in dept_reqs
            if r.status == OdStatus.APPROVED_AWAITING_EVIDENCE
            and not _is_escalated_to_dean(r)
        )
        completed = sum(1 for r in dept_reqs if r.status == OdStatus.COMPLETED)
        total = len(dept_reqs)
    elif current_user.role == UserRole.DEAN:
        approved_awaiting = sum(
            1 for r in all_reqs
            if r.status == OdStatus.APPROVED_AWAITING_EVIDENCE
            and _is_escalated_to_dean(r)
        )
        completed = sum(1 for r in all_reqs if r.status == OdStatus.COMPLETED and _is_escalated_to_dean(r))
        total = sum(1 for r in all_reqs if _is_escalated_to_dean(r))
    else:
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

@router.get("/shared-clearances", response_model=List[SharedClearanceResponse])
def get_shared_clearances(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(SharedOdClearance).filter(SharedOdClearance.is_deleted == False)
    if current_user.role in (UserRole.FACULTY_ADVISOR, UserRole.COORDINATOR, UserRole.HOD, UserRole.DEAN, UserRole.MASTER_ADMIN):
        query = query.filter(
            (SharedOdClearance.faculty_id == current_user.id) | 
            (SharedOdClearance.faculty_email.ilike(current_user.email))
        )
    elif current_user.role == UserRole.STUDENT:
        query = query.filter(SharedOdClearance.student_id == current_user.id)
    
    shares = query.order_by(SharedOdClearance.created_at.desc()).all()
    results = []
    for s in shares:
        req = s.od_request
        st = s.student
        results.append(
            SharedClearanceResponse(
                id=s.id,
                od_request_id=s.od_request_id,
                student_id=s.student_id,
                student_name=st.full_name if st else "Student",
                student_reg_no=st.username if st else "",
                student_program=st.program if st else "",
                student_year_section=st.year_section if st else "",
                faculty_id=s.faculty_id,
                faculty_email=s.faculty_email,
                faculty_name=s.faculty_name,
                reason=req.reason if req else "OD",
                purpose=req.purpose if req else "",
                start_date=str(req.start_date) if req else "",
                end_date=str(req.end_date) if req else "",
                duration_days=req.duration_days if req else 0,
                venue=req.venue if req else "",
                organizer=req.organizer if req else "",
                status=s.status.value,
                acknowledged_at=s.acknowledged_at,
                notes=s.notes,
                created_at=s.created_at
            )
        )
    return results

@router.post("/shared-clearances/{share_id}/acknowledge", response_model=SharedClearanceResponse)
def acknowledge_shared_clearance(
    share_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        val_id = UUID(share_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid share ID")

    share = db.query(SharedOdClearance).filter(SharedOdClearance.id == val_id, SharedOdClearance.is_deleted == False).first()
    if not share:
        raise HTTPException(status_code=404, detail="Shared clearance record not found")

    share.status = ClearanceShareStatus.ACKNOWLEDGED
    share.acknowledged_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(share)

    req = share.od_request
    st = share.student
    return SharedClearanceResponse(
        id=share.id,
        od_request_id=share.od_request_id,
        student_id=share.student_id,
        student_name=st.full_name if st else "Student",
        student_reg_no=st.username if st else "",
        student_program=st.program if st else "",
        student_year_section=st.year_section if st else "",
        faculty_id=share.faculty_id,
        faculty_email=share.faculty_email,
        faculty_name=share.faculty_name,
        reason=req.reason if req else "OD",
        purpose=req.purpose if req else "",
        start_date=str(req.start_date) if req else "",
        end_date=str(req.end_date) if req else "",
        duration_days=req.duration_days if req else 0,
        venue=req.venue if req else "",
        organizer=req.organizer if req else "",
        status=share.status.value,
        acknowledged_at=share.acknowledged_at,
        notes=share.notes,
        created_at=share.created_at
    )

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

@router.post("/{request_id}/share-clearance", response_model=SharedClearanceResponse)
def share_od_clearance(
    request_id: str,
    share_in: ShareClearanceRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    od_repo = OdRequestRepository(db)
    user_repo = UserRepository(db)
    noti_repo = NotificationRepository(db)
    noti_service = NotificationService(noti_repo)

    req = od_repo.get_by_id(request_id)
    if not req:
        raise HTTPException(status_code=404, detail="OD Request not found")

    if current_user.role == UserRole.STUDENT and req.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only share your own OD requests.")

    if req.status != OdStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Only completed and verified OD requests can be shared with course teachers.")

    target_email = share_in.faculty_email.strip().lower()
    target_faculty = db.query(User).filter(User.email.ilike(target_email), User.is_deleted == False).first()

    if not target_faculty:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No active faculty account found with email '{share_in.faculty_email.strip()}'. Please provide a registered faculty email in the institution."
        )

    if target_faculty.role not in [UserRole.FACULTY_ADVISOR, UserRole.COORDINATOR, UserRole.HOD, UserRole.DEAN]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"The email '{share_in.faculty_email.strip()}' belongs to a {target_faculty.role.value}, not a faculty/course teacher."
        )

    # Check if already shared
    existing = db.query(SharedOdClearance).filter(
        SharedOdClearance.od_request_id == request_id,
        SharedOdClearance.faculty_email.ilike(target_email),
        SharedOdClearance.is_deleted == False
    ).first()
    if existing:
        return SharedClearanceResponse(
            id=existing.id,
            od_request_id=existing.od_request_id,
            student_id=existing.student_id,
            student_name=req.student.full_name if req.student else current_user.full_name,
            student_reg_no=req.student.username if req.student else current_user.username,
            student_program=req.student.program if req.student else current_user.program,
            student_year_section=req.student.year_section if req.student else current_user.year_section,
            faculty_id=existing.faculty_id,
            faculty_email=existing.faculty_email,
            faculty_name=existing.faculty_name,
            reason=req.reason,
            purpose=req.purpose,
            start_date=str(req.start_date),
            end_date=str(req.end_date),
            duration_days=req.duration_days,
            venue=req.venue,
            organizer=req.organizer,
            status=existing.status.value,
            acknowledged_at=existing.acknowledged_at,
            notes=existing.notes,
            created_at=existing.created_at
        )

    share_record = SharedOdClearance(
        od_request_id=request_id,
        student_id=req.student_id,
        faculty_id=target_faculty.id,
        faculty_email=target_email,
        faculty_name=target_faculty.full_name,
        status=ClearanceShareStatus.SENT,
        notes=share_in.notes
    )
    db.add(share_record)
    db.commit()
    db.refresh(share_record)

    if target_faculty:
        noti_service.send_notification(
            recipient_id=target_faculty.id,
            title="Student OD Clearance Shared",
            message=f"{req.student.full_name if req.student else 'Student'} shared verified OD clearance for {req.reason} ({req.duration_days} days).",
            request_id=request_id
        )

    return SharedClearanceResponse(
        id=share_record.id,
        od_request_id=share_record.od_request_id,
        student_id=share_record.student_id,
        student_name=req.student.full_name if req.student else current_user.full_name,
        student_reg_no=req.student.username if req.student else current_user.username,
        student_program=req.student.program if req.student else current_user.program,
        student_year_section=req.student.year_section if req.student else current_user.year_section,
        faculty_id=share_record.faculty_id,
        faculty_email=share_record.faculty_email,
        faculty_name=share_record.faculty_name,
        reason=req.reason,
        purpose=req.purpose,
        start_date=str(req.start_date),
        end_date=str(req.end_date),
        duration_days=req.duration_days,
        venue=req.venue,
        organizer=req.organizer,
        status=share_record.status.value,
        acknowledged_at=share_record.acknowledged_at,
        notes=share_record.notes,
        created_at=share_record.created_at
    )
