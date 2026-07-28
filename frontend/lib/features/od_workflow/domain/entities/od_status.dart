import '../../../../core/ui/chips/app_status_chip.dart';

enum OdStatus {
  submitted,
  pendingFaculty,
  facultyApproved,
  facultyRejected,
  pendingCoordinator,
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
      case OdStatus.completed:
        return 'Approved';
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
        return AppStatusType.pending;
      case OdStatus.completed:
        return AppStatusType.approved;
      case OdStatus.facultyRejected:
      case OdStatus.rejected:
        return AppStatusType.error;
      case OdStatus.revisionRequested:
        return AppStatusType.warning;
    }
  }
}
