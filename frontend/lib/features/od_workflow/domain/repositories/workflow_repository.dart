import '../entities/attachment_item.dart';
import '../entities/notification_item.dart';
import '../entities/od_request.dart';

abstract class WorkflowRepository {
  Future<List<OdRequest>> getAllRequests();
  Future<List<OdRequest>> getStudentRequests(String studentId);
  Future<List<OdRequest>> getFacultyPendingRequests(String facultyId);
  Future<List<OdRequest>> getCoordinatorPendingRequests();
  Future<OdRequest> submitOdRequest({
    required String studentId,
    required String studentName,
    required String registerNumber,
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
    required String purpose,
    required String venue,
    required String organizer,
    String? additionalNotes,
    List<AttachmentItem>? attachments,
  });

  Future<void> facultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  });

  Future<void> coordinatorAction({
    required String requestId,
    required String coordinatorId,
    required String coordinatorName,
    required bool approve,
    bool returnForCorrection = false,
    String? comment,
  });

  Future<List<NotificationItem>> getNotifications(String recipientId);
  Future<void> markNotificationsRead(String recipientId);
}
