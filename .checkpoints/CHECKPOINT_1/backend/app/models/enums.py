import enum
from typing import Set, List

class UserRole(str, enum.Enum):
    STUDENT = "STUDENT"
    FACULTY_ADVISOR = "FACULTY_ADVISOR"
    COORDINATOR = "COORDINATOR"
    HOD = "HOD"
    DEAN = "DEAN"
    MASTER_ADMIN = "MASTER_ADMIN"

class OdStatus(str, enum.Enum):
    SUBMITTED = "SUBMITTED"
    PENDING_FACULTY = "PENDING_FACULTY"
    FACULTY_APPROVED = "FACULTY_APPROVED"
    FACULTY_REJECTED = "FACULTY_REJECTED"
    PENDING_COORDINATOR = "PENDING_COORDINATOR"
    APPROVED_AWAITING_EVIDENCE = "APPROVED_AWAITING_EVIDENCE"
    PENDING_EVIDENCE_FACULTY = "PENDING_EVIDENCE_FACULTY"
    PENDING_EVIDENCE_COORDINATOR = "PENDING_EVIDENCE_COORDINATOR"
    EVIDENCE_REVISION_REQUESTED = "EVIDENCE_REVISION_REQUESTED"
    COMPLETED = "COMPLETED"
    REJECTED = "REJECTED"
    REVISION_REQUESTED = "REVISION_REQUESTED"

class WorkflowStatusGroups:
    FACULTY_PENDING: List[OdStatus] = [
        OdStatus.PENDING_FACULTY,
        OdStatus.SUBMITTED,
        OdStatus.PENDING_EVIDENCE_FACULTY,
    ]

    COORDINATOR_PENDING: List[OdStatus] = [
        OdStatus.PENDING_COORDINATOR,
        OdStatus.FACULTY_APPROVED,
        OdStatus.PENDING_EVIDENCE_COORDINATOR,
    ]

    COMPLETED: List[OdStatus] = [
        OdStatus.COMPLETED,
    ]

    REJECTED: List[OdStatus] = [
        OdStatus.REJECTED,
        OdStatus.FACULTY_REJECTED,
    ]

    AWAITING_EVIDENCE: List[OdStatus] = [
        OdStatus.APPROVED_AWAITING_EVIDENCE,
    ]

    ACTION_REQUIRED_STUDENT: List[OdStatus] = [
        OdStatus.APPROVED_AWAITING_EVIDENCE,
        OdStatus.REVISION_REQUESTED,
        OdStatus.EVIDENCE_REVISION_REQUESTED,
    ]

class WorkflowTransitions:
    VALID_FACULTY_INITIAL: Set[OdStatus] = {OdStatus.PENDING_FACULTY, OdStatus.SUBMITTED}
    VALID_FACULTY_EVIDENCE: Set[OdStatus] = {OdStatus.PENDING_EVIDENCE_FACULTY}

    VALID_COORDINATOR_INITIAL: Set[OdStatus] = {OdStatus.PENDING_COORDINATOR, OdStatus.FACULTY_APPROVED}
    VALID_COORDINATOR_EVIDENCE: Set[OdStatus] = {OdStatus.PENDING_EVIDENCE_COORDINATOR}

    VALID_EVIDENCE_SUBMISSION: Set[OdStatus] = {OdStatus.APPROVED_AWAITING_EVIDENCE, OdStatus.EVIDENCE_REVISION_REQUESTED}

class WorkflowHelpers:
    @staticmethod
    def is_terminal_status(status: OdStatus) -> bool:
        return status in (OdStatus.COMPLETED, OdStatus.REJECTED, OdStatus.FACULTY_REJECTED)

    @staticmethod
    def is_pending_faculty(status: OdStatus) -> bool:
        return status in WorkflowStatusGroups.FACULTY_PENDING

    @staticmethod
    def is_pending_coordinator(status: OdStatus) -> bool:
        return status in WorkflowStatusGroups.COORDINATOR_PENDING
