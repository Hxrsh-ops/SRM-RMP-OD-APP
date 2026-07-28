from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from ....core.database import get_db
from ....repositories.user_repository import UserRepository
from ....repositories.od_request_repository import OdRequestRepository
from ....repositories.notification_repository import NotificationRepository
from ....services.notification_service import NotificationService
from ....services.workflow_service import WorkflowService
from ....schemas.od_request import OdRequestCreate, OdRequestResponse, FacultyActionRequest, CoordinatorActionRequest
from ....models.user import User
from ....models.enums import UserRole
from ...dependencies import get_current_user, require_roles

router = APIRouter()

def get_workflow_service(db: Session = Depends(get_db)) -> WorkflowService:
    od_repo = OdRequestRepository(db)
    user_repo = UserRepository(db)
    noti_repo = NotificationRepository(db)
    noti_service = NotificationService(noti_repo)
    return WorkflowService(od_repo, user_repo, noti_service)

@router.get("", response_model=List[OdRequestResponse])
def list_od_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    od_repo = OdRequestRepository(db)
    if current_user.role == UserRole.FACULTY_ADVISOR:
        return od_repo.list_faculty_pending(current_user.id)
    elif current_user.role == UserRole.COORDINATOR:
        return od_repo.list_coordinator_pending()
    elif current_user.role == UserRole.STUDENT:
        return od_repo.list_by_student(current_user.id)
    else:
        return od_repo.list_all()

@router.post("", response_model=OdRequestResponse, status_code=status.HTTP_201_CREATED)
def create_od_request(
    req_in: OdRequestCreate,
    current_user: User = Depends(require_roles([UserRole.STUDENT])),
    workflow_service: WorkflowService = Depends(get_workflow_service)
):
    return workflow_service.create_od_request(current_user.id, req_in)

@router.get("/{request_id}", response_model=OdRequestResponse)
def get_od_request_by_id(
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    od_repo = OdRequestRepository(db)
    req = od_repo.get_by_id(request_id)
    if not req:
        from ....core.exceptions import NotFoundException
        raise NotFoundException("OD Request not found")
    return req

@router.post("/{request_id}/faculty-action", response_model=OdRequestResponse)
def faculty_action(
    request_id: str,
    action: FacultyActionRequest,
    current_user: User = Depends(require_roles([UserRole.FACULTY_ADVISOR])),
    workflow_service: WorkflowService = Depends(get_workflow_service)
):
    return workflow_service.process_faculty_action(request_id, current_user.id, action)

@router.post("/{request_id}/coordinator-action", response_model=OdRequestResponse)
def coordinator_action(
    request_id: str,
    action: CoordinatorActionRequest,
    current_user: User = Depends(require_roles([UserRole.COORDINATOR])),
    workflow_service: WorkflowService = Depends(get_workflow_service)
):
    return workflow_service.process_coordinator_action(request_id, current_user.id, action)
