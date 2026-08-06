import uuid
from datetime import datetime, timezone, date
from typing import List, Optional, Dict, Any
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

        # Calendar Date & Duration Validation
        if req_in.end_date < req_in.start_date:
            raise BadRequestException("End date cannot be prior to start date.")
        expected_duration = (req_in.end_date - req_in.start_date).days + 1
        if req_in.duration_days <= 0 or req_in.duration_days != expected_duration:
            req_in.duration_days = expected_duration

        # Hosteller Parent Consent Validation
        if req_in.residence_type == "Hosteller":
            has_parent_consent = bool(req_in.parent_consent_url) or any(
                att.document_category == "parent_consent" or "consent" in att.file_name.lower() or "parent" in att.file_name.lower()
                for att in (req_in.attachments or [])
            )
            if not has_parent_consent:
                raise BadRequestException("Hosteller students MUST provide a valid parent consent document.")

        # Determine Faculty Advisor dynamically
        faculty_id = student.assigned_faculty_id
        if not faculty_id:
            faculty = self.user_repo.get_by_role(UserRole.FACULTY_ADVISOR, department_id=student.department_id)
            if not faculty:
                faculty = self.user_repo.get_by_username("FA1001")
            faculty_id = faculty.id if faculty else student_id

        # Collision-safe ID generation
        new_id = f"OD-2026-{uuid.uuid4().hex[:6].upper()}"

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
            cgpa=req_in.cgpa or 8.5,
            attendance_percentage=req_in.attendance_percentage or 88.0,
            residence_type=req_in.residence_type or "Day Scholar",
            parent_consent_url=req_in.parent_consent_url,
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
                        document_category=att_in.document_category or "supporting_document",
                        uploaded_by=student.full_name,
                        uploaded_at=now
                    )
                )

        # Audit Trail Timeline
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
        faculty_name = faculty_user.full_name if faculty_user else "Faculty Advisor"
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

        # Object-level authorization check
        if req.faculty_id != faculty_user_id:
            raise PermissionDeniedException("You are not the assigned Faculty Advisor for this request.")

        # Require non-empty comment on rejection
        if not action.approve and (not action.comment or not action.comment.strip()):
            raise BadRequestException("Faculty rejection or revision request requires a valid explanation note.")

        faculty_user = self.user_repo.get_by_id(faculty_user_id)
        faculty_name = faculty_user.full_name if faculty_user else "Faculty Advisor"
        now = datetime.now(timezone.utc)

        # Process depending on current state
        if req.status in (OdStatus.PENDING_FACULTY, OdStatus.SUBMITTED):
            new_status = OdStatus.PENDING_COORDINATOR if action.approve else OdStatus.FACULTY_REJECTED
            step_title = "Faculty Advisor Approved" if action.approve else "Faculty Advisor Rejected"
        elif req.status == OdStatus.PENDING_EVIDENCE_FACULTY:
            new_status = OdStatus.PENDING_EVIDENCE_COORDINATOR if action.approve else OdStatus.EVIDENCE_REVISION_REQUESTED
            step_title = "Faculty Verified Evidence" if action.approve else "Faculty Requested Evidence Revision"
        else:
            raise BadRequestException(f"Cannot perform faculty action on request in status {req.status.value}")

        req.status = new_status
        req.updated_at = now
        if action.approve and req.status == OdStatus.PENDING_COORDINATOR:
            req.faculty_approval_time = now

        req.timeline.append(
            TimelineEvent(
                title=step_title,
                actor_name=faculty_name,
                actor_role="Faculty Advisor",
                status=new_status,
                note=action.comment or step_title,
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
            title=step_title,
            message=f"Faculty Advisor {faculty_name} updated request {request_id}.",
            request_id=request_id
        )

        if action.approve:
            student = self.user_repo.get_by_id(req.student_id)
            dept_id = student.department_id if student else None
            coord = self.user_repo.get_by_role(UserRole.COORDINATOR, department_id=dept_id)
            if not coord:
                coord = self.user_repo.get_by_username("CO1001")
            if coord:
                self.notification_service.send_notification(
                    recipient_id=coord.id,
                    title=f"Request {request_id} Ready for Coordinator",
                    message=f"Faculty {faculty_name} approved request {request_id}. Pending your review.",
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
        if not coordinator_user or coordinator_user.role not in (UserRole.COORDINATOR, UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.DEAN):
            raise PermissionDeniedException("Only Coordinators can perform this action.")

        # Require non-empty comment on rejection or return for correction
        if (not action.approve or action.return_for_correction) and (not action.comment or not action.comment.strip()):
            raise BadRequestException("Coordinator rejection or return for correction requires a valid reason note.")

        coordinator_name = coordinator_user.full_name if coordinator_user else "Coordinator"
        now = datetime.now(timezone.utc)

        if req.status == OdStatus.PENDING_COORDINATOR:
            if action.return_for_correction:
                new_status = OdStatus.REVISION_REQUESTED
                step_title = "Returned for Correction"
            elif action.approve:
                new_status = OdStatus.APPROVED_AWAITING_EVIDENCE
                step_title = "Coordinator Approved (Awaiting Event Completion Evidence)"
            else:
                new_status = OdStatus.REJECTED
                step_title = "Coordinator Rejected"
        elif req.status == OdStatus.PENDING_EVIDENCE_COORDINATOR:
            if action.return_for_correction or not action.approve:
                new_status = OdStatus.EVIDENCE_REVISION_REQUESTED
                step_title = "Coordinator Requested Evidence Revision"
            else:
                new_status = OdStatus.COMPLETED
                step_title = "Completion Verified & OD Granted"
                req.completion_verified_at = now
        else:
            raise BadRequestException(f"Cannot perform coordinator action on request in status {req.status.value}")

        req.status = new_status
        req.updated_at = now

        req.timeline.append(
            TimelineEvent(
                title=step_title,
                actor_name=coordinator_name,
                actor_role="Coordinator",
                status=new_status,
                note=action.comment or step_title,
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
            title=step_title,
            message=f"Coordinator {coordinator_name} updated request {request_id}.",
            request_id=request_id
        )

        return updated_req

    def submit_completion_evidence(
        self,
        request_id: str,
        student_user_id: UUID,
        completion_summary: str,
        attachments_info: List[Dict[str, Any]]
    ) -> OdRequest:
        req = self.od_repo.get_by_id(request_id)
        if not req:
            raise NotFoundException("OD Request not found")

        if req.student_id != student_user_id:
            raise PermissionDeniedException("You can only submit completion evidence for your own OD request.")

        # Require completion summary and at least one proof document
        if not completion_summary or not completion_summary.strip():
            raise BadRequestException("A written completion summary is required.")

        if not attachments_info:
            raise BadRequestException("At least one evidence proof document is required.")

        # Validate event end date
        today = date.today()
        if today < req.start_date or today < req.end_date:
            raise BadRequestException("Completion proof can only be submitted on or after the event end date.")

        # Validate request status
        if req.status not in (OdStatus.APPROVED_AWAITING_EVIDENCE, OdStatus.EVIDENCE_REVISION_REQUESTED):
            raise BadRequestException(f"Cannot submit completion evidence for request in status {req.status.value}")

        student = self.user_repo.get_by_id(student_user_id)
        student_name = student.full_name if student else "Student"
        now = datetime.now(timezone.utc)

        req.completion_summary = completion_summary.strip()
        req.completion_submitted_at = now
        req.status = OdStatus.PENDING_EVIDENCE_FACULTY
        req.updated_at = now

        for att_info in attachments_info:
            req.attachments.append(
                Attachment(
                    file_name=att_info["file_name"],
                    file_type=att_info["file_type"],
                    size_bytes=att_info["size_bytes"],
                    file_url=att_info["file_url"],
                    document_category="completion_evidence",
                    uploaded_by=student_name,
                    uploaded_at=now
                )
            )

        req.timeline.append(
            TimelineEvent(
                title="Completion Evidence Submitted",
                actor_name=student_name,
                actor_role="Student",
                status=OdStatus.PENDING_EVIDENCE_FACULTY,
                note=f"Submitted completion report: {completion_summary.strip()[:100]}...",
                timestamp=now
            )
        )

        updated_req = self.od_repo.update(req)

        # Notify Faculty Advisor
        if req.faculty_id:
            self.notification_service.send_notification(
                recipient_id=req.faculty_id,
                title="Completion Evidence Submitted",
                message=f"Student {student_name} submitted completion proof for {request_id}. Pending your verification.",
                request_id=request_id
            )

        return updated_req

    def get_coordinator_analytics(self) -> Dict[str, int]:
        return self.od_repo.count_by_status()
