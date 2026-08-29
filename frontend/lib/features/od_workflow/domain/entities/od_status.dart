import '../../../../core/ui/chips/app_status_chip.dart';

enum OdStatus {
  submitted,
  pendingFaculty,
  facultyApproved,
  facultyRejected,
  pendingCoordinator,
  approvedAwaitingEvidence,
  pendingEvidenceFaculty,
  pendingEvidenceCoordinator,
  evidenceRevisionRequested,
  completed,
  rejected,
  revisionRequested;

  String get displayName {
    switch (this) {
      case OdStatus.submitted:
        return 'Submitted';
      case OdStatus.pendingFaculty:
        return 'Pending FA Approval';
      case OdStatus.facultyApproved:
        return 'FA Approved';
      case OdStatus.facultyRejected:
        return 'FA Rejected';
      case OdStatus.pendingCoordinator:
        return 'Pending Coordinator';
      case OdStatus.approvedAwaitingEvidence:
        return 'Awaiting Proof';
      case OdStatus.pendingEvidenceFaculty:
        return 'Pending FA Proof';
      case OdStatus.pendingEvidenceCoordinator:
        return 'Pending Proof Review';
      case OdStatus.evidenceRevisionRequested:
        return 'Proof Revision';
      case OdStatus.completed:
        return 'Completed';
      case OdStatus.rejected:
        return 'Rejected';
      case OdStatus.revisionRequested:
        return 'Revision Requested';
    }
  }

  AppStatusType get statusType {
    switch (this) {
      case OdStatus.submitted:
      case OdStatus.pendingFaculty:
      case OdStatus.pendingCoordinator:
        return AppStatusType.pending;
      case OdStatus.facultyApproved:
        return AppStatusType.approved;
      case OdStatus.approvedAwaitingEvidence:
        return AppStatusType.awaitingEvidence;
      case OdStatus.pendingEvidenceFaculty:
      case OdStatus.pendingEvidenceCoordinator:
        return AppStatusType.evidenceReview;
      case OdStatus.completed:
        return AppStatusType.approved;
      case OdStatus.facultyRejected:
      case OdStatus.rejected:
        return AppStatusType.rejected;
      case OdStatus.evidenceRevisionRequested:
      case OdStatus.revisionRequested:
        return AppStatusType.revisionRequested;
    }
  }

  static OdStatus fromApiString(String raw) {
    final s = raw.toUpperCase().trim();
    switch (s) {
      case 'SUBMITTED':
        return OdStatus.submitted;
      case 'PENDING_FACULTY':
        return OdStatus.pendingFaculty;
      case 'FACULTY_APPROVED':
        return OdStatus.facultyApproved;
      case 'FACULTY_REJECTED':
        return OdStatus.facultyRejected;
      case 'PENDING_COORDINATOR':
        return OdStatus.pendingCoordinator;
      case 'APPROVED_AWAITING_EVIDENCE':
        return OdStatus.approvedAwaitingEvidence;
      case 'PENDING_EVIDENCE_FACULTY':
        return OdStatus.pendingEvidenceFaculty;
      case 'PENDING_EVIDENCE_COORDINATOR':
        return OdStatus.pendingEvidenceCoordinator;
      case 'EVIDENCE_REVISION_REQUESTED':
        return OdStatus.evidenceRevisionRequested;
      case 'COMPLETED':
        return OdStatus.completed;
      case 'REJECTED':
        return OdStatus.rejected;
      case 'REVISION_REQUESTED':
        return OdStatus.revisionRequested;
      default:
        return OdStatus.pendingFaculty;
    }
  }
}
