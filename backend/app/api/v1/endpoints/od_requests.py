from typing import List, Optional
from fastapi import APIRouter, Depends, status, UploadFile, File, Form, HTTPException, Query
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
from ....models.enums import UserRole
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

    return resp

@router.get("", response_model=List[OdRequestResponse])
def list_od_requests(
    include_history: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    od_repo = OdRequestRepository(db)
    user_repo = UserRepository(db)
    if current_user.role == UserRole.FACULTY_ADVISOR:
        requests = od_repo.list_faculty_all(current_user.id) if include_history else od_repo.list_faculty_pending(current_user.id)
    elif current_user.role == UserRole.COORDINATOR:
        requests = od_repo.list_coordinator_all() if include_history else od_repo.list_coordinator_pending()
    elif current_user.role == UserRole.STUDENT:
        requests = od_repo.list_by_student(current_user.id)
    else:
        requests = od_repo.list_all()

    return [_build_od_response(req, user_repo) for req in requests]

@router.get("/analytics/coordinator", response_model=CoordinatorAnalyticsResponse)
def get_coordinator_analytics(
    current_user: User = Depends(require_roles([UserRole.COORDINATOR, UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.DEAN])),
    workflow_service: WorkflowService = Depends(get_workflow_service),
):
    counts = workflow_service.get_coordinator_analytics()
    return CoordinatorAnalyticsResponse(**counts)

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
