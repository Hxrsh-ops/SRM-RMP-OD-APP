import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/comment_item.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/od_request.dart';
import '../../domain/entities/od_status.dart';
import '../../domain/entities/timeline_step.dart';
import '../../domain/repositories/workflow_repository.dart';

class ApiWorkflowRepository implements WorkflowRepository {
  final ApiClient apiClient;

  ApiWorkflowRepository({required this.apiClient});

  @override
  Future<List<OdRequest>> getAllRequests() async {
    final List response = await apiClient.get(ApiConstants.odRequests);
    return response.map((json) => _mapJsonToOdRequest(json)).toList();
  }

  @override
  Future<List<OdRequest>> getStudentRequests(String studentId) async {
    return getAllRequests();
  }

  @override
  Future<List<OdRequest>> getFacultyPendingRequests(String facultyId) async {
    return getAllRequests();
  }

  @override
  Future<List<OdRequest>> getCoordinatorPendingRequests() async {
    return getAllRequests();
  }

  @override
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
  }) async {
    final response = await apiClient.post(
      ApiConstants.odRequests,
      data: {
        'reason': reason,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'duration_days': durationDays,
        'purpose': purpose,
        'venue': venue,
        'organizer': organizer,
        'additional_notes': additionalNotes,
        'attachments': attachments
                ?.map((a) => {
                      'file_name': a.fileName,
                      'file_type': a.fileType,
                      'size_bytes': a.sizeBytes,
                      'file_url': a.fileUrl,
                      'uploaded_by': a.uploadedBy,
                      'uploaded_at': a.uploadedAt.toIso8601String(),
                    })
                .toList() ??
            [],
      },
    );

    return _mapJsonToOdRequest(response);
  }

  @override
  Future<void> facultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  }) async {
    await apiClient.post(
      ApiConstants.facultyAction(requestId),
      data: {
        'approve': approve,
        'comment': comment,
      },
    );
  }

  @override
  Future<void> coordinatorAction({
    required String requestId,
    required String coordinatorId,
    required String coordinatorName,
    required bool approve,
    bool returnForCorrection = false,
    String? comment,
  }) async {
    await apiClient.post(
      ApiConstants.coordinatorAction(requestId),
      data: {
        'approve': approve,
        'return_for_correction': returnForCorrection,
        'comment': comment,
      },
    );
  }

  @override
  Future<List<NotificationItem>> getNotifications(String recipientId) async {
    final List response = await apiClient.get(ApiConstants.notifications);
    return response.map((json) {
      return NotificationItem(
        id: json['id'].toString(),
        recipientId: json['recipient_id'].toString(),
        title: json['title'].toString(),
        message: json['message'].toString(),
        isRead: json['is_read'] as bool,
        requestId: json['request_id']?.toString(),
        timestamp: DateTime.parse(json['timestamp'].toString()),
      );
    }).toList();
  }

  @override
  Future<void> markNotificationsRead(String recipientId) async {
    await apiClient.patch(ApiConstants.markNotificationsRead);
  }

  OdRequest _mapJsonToOdRequest(Map<String, dynamic> json) {
    final statusStr = json['status'].toString().toUpperCase();
    OdStatus status = OdStatus.pendingFaculty;

    if (statusStr.contains('COORDINATOR')) {
      status = OdStatus.pendingCoordinator;
    } else if (statusStr.contains('COMPLETED') || statusStr.contains('APPROVED')) {
      status = OdStatus.completed;
    } else if (statusStr.contains('REJECTED')) {
      status = OdStatus.rejected;
    }

    final attachmentsList = (json['attachments'] as List? ?? []).map((att) {
      return AttachmentItem(
        id: att['id']?.toString() ?? '',
        fileName: att['file_name'].toString(),
        fileType: att['file_type'].toString(),
        sizeBytes: att['size_bytes'] as int,
        fileUrl: att['file_url'].toString(),
        uploadedBy: att['uploaded_by'].toString(),
        uploadedAt: DateTime.parse(att['uploaded_at'].toString()),
      );
    }).toList();

    final timelineList = (json['timeline'] as List? ?? []).map((t) {
      return TimelineStep(
        id: t['id']?.toString() ?? '',
        title: t['title'].toString(),
        actorName: t['actor_name'].toString(),
        actorRole: t['actor_role'].toString(),
        status: status,
        note: t['note']?.toString(),
        timestamp: DateTime.parse(t['timestamp'].toString()),
      );
    }).toList();

    final commentsList = (json['comments'] as List? ?? []).map((c) {
      return CommentItem(
        id: c['id']?.toString() ?? '',
        authorName: c['author_name'].toString(),
        authorRole: c['author_role'].toString(),
        text: c['text'].toString(),
        timestamp: DateTime.parse(c['timestamp'].toString()),
      );
    }).toList();

    return OdRequest(
      id: json['id'].toString(),
      studentId: json['student_id'].toString(),
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2510026020400',
      reason: json['reason'].toString(),
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      durationDays: json['duration_days'] as int,
      purpose: json['purpose'].toString(),
      venue: json['venue'].toString(),
      organizer: json['organizer'].toString(),
      additionalNotes: json['additional_notes']?.toString(),
      facultyAdvisorId: json['faculty_id']?.toString() ?? '',
      facultyAdvisorName: 'Dr. Karthik B (Mock)',
      status: status,
      createdAt: DateTime.parse(json['created_at'].toString()),
      attachments: attachmentsList,
      timeline: timelineList,
      comments: commentsList,
    );
  }
}
