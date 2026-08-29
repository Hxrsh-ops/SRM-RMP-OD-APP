import '../entities/attachment_item.dart';
import '../entities/notification_item.dart';
import '../entities/od_request.dart';

abstract class WorkflowRepository {
  Future<List<OdRequest>> getMyRequests({bool includeHistory = false});
  Future<OdRequest> getRequestById(String id);
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
    double? cgpa,
    double? attendancePercentage,
    String? residenceType,
    String? parentConsentUrl,
    List<AttachmentItem>? attachments,
  });

  Future<OdRequest> facultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  });

  Future<OdRequest> coordinatorAction({
    required String requestId,
    required String coordinatorId,
    required String coordinatorName,
    required bool approve,
    bool returnForCorrection = false,
    String? escalateTo,
    String? comment,
  });

  Future<OdRequest> submitCompletionEvidence({
    required String requestId,
    required String completionSummary,
    required List<List<int>> filesBytes,
    required List<String> fileNames,
  });

  Future<Map<String, int>> getCoordinatorAnalytics();

  Future<List<NotificationItem>> getNotifications(String recipientId);
  Future<void> markNotificationsRead(String recipientId);
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteNotificationsBulk({List<String>? ids});
  Future<AttachmentItem> uploadAttachment({
    required List<int> fileBytes,
    required String fileName,
    required String documentCategory,
  });

  Future<List<Map<String, dynamic>>> getFacultyAdvisees();
  Future<Map<String, dynamic>> getAdviseeRecords(String studentId);
  Future<List<Map<String, dynamic>>> getDepartmentStudentDirectory({int limit = 30});
  Future<List<Map<String, dynamic>>> searchStudents(String query, {int limit = 30});
  Future<Map<String, dynamic>> getStudentRecords(String studentId);
  Future<String> exportDepartmentOdCsv();
}
