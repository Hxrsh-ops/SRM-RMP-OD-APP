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
        return 'Pending Faculty';
      case OdStatus.facultyApproved:
        return 'Faculty Approved';
      case OdStatus.facultyRejected:
        return 'Faculty Rejected';
      case OdStatus.pendingCoordinator:
        return 'Pending Coordinator';
      case OdStatus.approvedAwaitingEvidence:
        return 'Approved - Awaiting Proof';
      case OdStatus.pendingEvidenceFaculty:
        return 'Proof - Pending Faculty';
      case OdStatus.pendingEvidenceCoordinator:
        return 'Proof - Pending Coordinator';
      case OdStatus.evidenceRevisionRequested:
        return 'Proof Revision Requested';
      case OdStatus.completed:
        return 'Completed & Granted';
      case OdStatus.rejected:
        return 'Rejected';
      case OdStatus.revisionRequested:
        return 'Needs Revision';
    }
  }

  AppStatusType get statusType {
    switch (this) {
      case OdStatus.submitted:
      case OdStatus.pendingFaculty:
      case OdStatus.facultyApproved:
      case OdStatus.pendingCoordinator:
      case OdStatus.approvedAwaitingEvidence:
        return AppStatusType.pending;
      case OdStatus.pendingEvidenceFaculty:
      case OdStatus.pendingEvidenceCoordinator:
        return AppStatusType.warning;
      case OdStatus.completed:
        return AppStatusType.approved;
      case OdStatus.facultyRejected:
      case OdStatus.rejected:
      case OdStatus.evidenceRevisionRequested:
      case OdStatus.revisionRequested:
        return AppStatusType.error;
    }
  }
}
