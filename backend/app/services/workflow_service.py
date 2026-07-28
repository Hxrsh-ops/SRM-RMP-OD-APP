from datetime import datetime, timezone
from typing import List, Optional
from uuid import UUID
from ..core.exceptions import NotFoundException, PermissionDeniedException, BadRequestException
from ..repositories.od_request_repository import OdRequestRepository
from ..repositories.user_repository import UserRepository
from ..services.notification_service import NotificationService
from ..models.od_request import OdRequest
from ..models.attachment import Attachment
from ..models.timeline import TimelineEvent
from ..models.comment import Comment
from ..models.enums import OdStatus, UserRole
from ..schemas.od_request import OdRequestCreate, FacultyActionRequest, CoordinatorActionRequest

class WorkflowService:
    def __init__(
        self,
        od_repo: OdRequestRepository,
        user_repo: UserRepository,
        notification_service: NotificationService
    ):
        self.od_repo = od_repo
        self.user_repo = user_repo
        self.notification_service = notification_service

    def create_od_request(self, student_id: UUID, req_in: OdRequestCreate) -> OdRequest:
        student = self.user_repo.get_by_id(student_id)
        if not student:
            raise NotFoundException("Student record not found")

        # Determine Faculty Advisor
        faculty_id = student.assigned_faculty_id
        if not faculty_id:
            faculty = self.user_repo.get_by_username("FA1001")
            faculty_id = faculty.id if faculty else student_id

        all_requests = self.od_repo.list_all()
        request_number = len(all_requests) + 1
        new_id = f"OD-2026-{request_number:03d}"

        now = datetime.now(timezone.utc)
        od = OdRequest(
            id=new_id,
            student_id=student_id,
            faculty_id=faculty_id,
            reason=req_in.reason,
            start_date=req_in.start_date,
            end_date=req_in.end_date,
            duration_days=req_in.duration_days,
            purpose=req_in.purpose,
            venue=req_in.venue,
            organizer=req_in.organizer,
            additional_notes=req_in.additional_notes,
            status=OdStatus.PENDING_FACULTY,
            created_at=now,
            updated_at=now
        )

        if req_in.attachments:
            for att_in in req_in.attachments:
                od.attachments.append(
                    Attachment(
                        file_name=att_in.file_name,
                        file_type=att_in.file_type,
                        size_bytes=att_in.size_bytes,
                        file_url=att_in.file_url,
                        uploaded_by=student.full_name,
                        uploaded_at=now
                    )
                )

        # Audit Trail Timeline Step 1 & 2
        od.timeline.append(
            TimelineEvent(
                title="Request Submitted",
                actor_name=student.full_name,
                actor_role="Student",
                status=OdStatus.SUBMITTED,
                note=f"Submitted On Duty request for {req_in.reason}",
                timestamp=now
            )
        )
        faculty_user = self.user_repo.get_by_id(faculty_id)
        faculty_name = faculty_user.full_name if faculty_user else "Dr. Karthik B"
        od.timeline.append(
            TimelineEvent(
                title="Assigned to Faculty Advisor",
                actor_name=faculty_name,
                actor_role="Faculty Advisor",
                status=OdStatus.PENDING_FACULTY,
                note="Awaiting Faculty Advisor review",
                timestamp=now
            )
        )

        saved_request = self.od_repo.create(od)

        # Trigger Notifications
        self.notification_service.send_notification(
            recipient_id=student_id,
            title="OD Request Submitted",
            message=f"Your OD request for {req_in.reason} has been submitted successfully.",
            request_id=new_id
        )
        if faculty_id:
            self.notification_service.send_notification(
                recipient_id=faculty_id,
                title="New OD Request Assigned",
                message=f"{student.full_name} submitted OD request {new_id} for your approval.",
                request_id=new_id
            )

        return saved_request

    def process_faculty_action(
        self,
        request_id: str,
        faculty_user_id: UUID,
        action: FacultyActionRequest
    ) -> OdRequest:
        req = self.od_repo.get_by_id(request_id)
        if not req:
            raise NotFoundException("OD Request not found")

        faculty_user = self.user_repo.get_by_id(faculty_user_id)
        faculty_name = faculty_user.full_name if faculty_user else "Faculty Advisor"

        now = datetime.now(timezone.utc)
        new_status = OdStatus.PENDING_COORDINATOR if action.approve else OdStatus.FACULTY_REJECTED

        req.status = new_status
        req.updated_at = now

        req.timeline.append(
            TimelineEvent(
                title="Faculty Advisor Approved" if action.approve else "Faculty Advisor Rejected",
                actor_name=faculty_name,
                actor_role="Faculty Advisor",
                status=new_status,
                note=action.comment or ("Approved by Faculty Advisor" if action.approve else "Rejected by Faculty Advisor"),
                timestamp=now
            )
        )

        if action.comment and action.comment.strip():
            req.comments.append(
                Comment(
                    author_name=faculty_name,
                    author_role="Faculty Advisor",
                    text=action.comment.strip(),
                    timestamp=now
                )
            )

        updated_req = self.od_repo.update(req)

        self.notification_service.send_notification(
            recipient_id=req.student_id,
            title="Faculty Approved OD" if action.approve else "Faculty Rejected OD",
            message=f"Faculty Advisor {faculty_name} {'approved' if action.approve else 'rejected'} your request {request_id}.",
            request_id=request_id
        )

        return updated_req

    def process_coordinator_action(
        self,
        request_id: str,
        coordinator_user_id: UUID,
        action: CoordinatorActionRequest
    ) -> OdRequest:
        req = self.od_repo.get_by_id(request_id)
        if not req:
            raise NotFoundException("OD Request not found")

        coordinator_user = self.user_repo.get_by_id(coordinator_user_id)
        coordinator_name = coordinator_user.full_name if coordinator_user else "Coordinator"

        now = datetime.now(timezone.utc)
        if action.return_for_correction:
            new_status = OdStatus.REVISION_REQUESTED
            step_title = "Returned for Correction"
        elif action.approve:
            new_status = OdStatus.COMPLETED
            step_title = "Final Approval Granted"
        else:
            new_status = OdStatus.REJECTED
            step_title = "Coordinator Rejected"

        req.status = new_status
        req.updated_at = now

        req.timeline.append(
            TimelineEvent(
                title=step_title,
                actor_name=coordinator_name,
                actor_role="Coordinator",
                status=new_status,
                note=action.comment or f"Processed by {coordinator_name}",
                timestamp=now
            )
        )

        if action.comment and action.comment.strip():
            req.comments.append(
                Comment(
                    author_name=coordinator_name,
                    author_role="Coordinator",
                    text=action.comment.strip(),
                    timestamp=now
                )
            )

        updated_req = self.od_repo.update(req)

        self.notification_service.send_notification(
            recipient_id=req.student_id,
            title=f"OD {new_status.value.capitalize()}",
            message=f"Coordinator {coordinator_name} updated your request {request_id}.",
            request_id=request_id
        )

        return updated_req
