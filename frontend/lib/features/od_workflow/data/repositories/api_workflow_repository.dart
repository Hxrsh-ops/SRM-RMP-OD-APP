import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/od_request.dart';
import '../../domain/entities/od_status.dart';
import '../../domain/entities/timeline_step.dart';
import '../../domain/entities/comment_item.dart';
import '../../domain/repositories/workflow_repository.dart';

class ApiWorkflowRepository implements WorkflowRepository {
  final ApiClient apiClient;

  ApiWorkflowRepository({required this.apiClient});

  @override
  Future<List<OdRequest>> getMyRequests({bool includeHistory = false}) async {
    final response = await apiClient.get(
      ApiConstants.odRequests,
      queryParameters: includeHistory ? {'include_history': 'true'} : null,
    );
    final list = response as List;
    return list.map((item) => _mapJsonToOdRequest(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<OdRequest> getRequestById(String id) async {
    final response = await apiClient.get(ApiConstants.odRequestById(id));
    return _mapJsonToOdRequest(response as Map<String, dynamic>);
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
    double? cgpa,
    double? attendancePercentage,
    String? residenceType,
    String? parentConsentUrl,
    List<AttachmentItem>? attachments,
  }) async {
    final body = {
      'reason': reason,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'duration_days': durationDays,
      'purpose': purpose,
      'venue': venue,
      'organizer': organizer,
      'additional_notes': additionalNotes,
      'cgpa': cgpa,
      'attendance_percentage': attendancePercentage,
      'residence_type': residenceType ?? 'Day Scholar',
      'parent_consent_url': parentConsentUrl,
      'attachments': (attachments ?? []).map((a) => {
        'file_name': a.fileName,
        'file_type': a.fileType,
        'size_bytes': a.sizeBytes,
        'file_url': a.fileUrl,
        'uploaded_by': a.uploadedBy.isNotEmpty ? a.uploadedBy : studentName,
        'uploaded_at': a.uploadedAt.toIso8601String(),
        'document_category': a.fileName.toLowerCase().contains('consent') || a.fileName.toLowerCase().contains('parent') ? 'parent_consent' : 'pre_approval_support',
      }).toList(),
    };

    final response = await apiClient.post(ApiConstants.odRequests, data: body);
    return _mapJsonToOdRequest(response as Map<String, dynamic>);
  }

  @override
  Future<OdRequest> facultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  }) async {
    final response = await apiClient.post(
      ApiConstants.facultyAction(requestId),
      data: {
        'approve': approve,
        'comment': comment,
      },
    );
    return _mapJsonToOdRequest(response as Map<String, dynamic>);
  }

  @override
  Future<OdRequest> coordinatorAction({
    required String requestId,
    required String coordinatorId,
    required String coordinatorName,
    required bool approve,
    bool returnForCorrection = false,
    String? escalateTo,
    String? comment,
  }) async {
    final response = await apiClient.post(
      ApiConstants.coordinatorAction(requestId),
      data: {
        'approve': approve,
        'return_for_correction': returnForCorrection,
        if (escalateTo != null) 'escalate_to': escalateTo,
        'comment': comment,
      },
    );
    return _mapJsonToOdRequest(response as Map<String, dynamic>);
  }

  @override
  Future<OdRequest> submitCompletionEvidence({
    required String requestId,
    required String completionSummary,
    required List<List<int>> filesBytes,
    required List<String> fileNames,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('completion_summary', completionSummary));
    for (int i = 0; i < filesBytes.length; i++) {
      formData.files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(filesBytes[i], filename: fileNames[i]),
      ));
    }
    final response = await apiClient.post(ApiConstants.completionEvidence(requestId), data: formData);
    return _mapJsonToOdRequest(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, int>> getCoordinatorAnalytics() async {
    final response = await apiClient.get(ApiConstants.coordinatorAnalytics);
    final map = response as Map<String, dynamic>;
    return {
      'pending_coordinator_count': map['pending_coordinator_count'] as int? ?? 0,
      'approved_awaiting_evidence_count': map['approved_awaiting_evidence_count'] as int? ?? 0,
      'pending_evidence_coordinator_count': map['pending_evidence_coordinator_count'] as int? ?? 0,
      'completed_count': map['completed_count'] as int? ?? 0,
      'total_submissions_count': map['total_submissions_count'] as int? ?? 0,
    };
  }

  @override
  Future<List<NotificationItem>> getNotifications(String recipientId) async {
    final response = await apiClient.get(ApiConstants.notifications);
    final list = response as List;
    return list.map((item) {
      final json = item as Map<String, dynamic>;
      return NotificationItem(
        id: json['id'].toString(),
        recipientId: json['recipient_id'].toString(),
        title: json['title'].toString(),
        message: json['message'].toString(),
        requestId: json['request_id']?.toString(),
        isRead: json['is_read'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'].toString()),
      );
    }).toList();
  }

  @override
  Future<void> markNotificationsRead(String recipientId) async {
    await apiClient.post(ApiConstants.markNotificationsRead);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await apiClient.delete('/notifications/$notificationId');
  }

  @override
  Future<void> deleteNotificationsBulk({List<String>? ids}) async {
    await apiClient.post('/notifications/bulk-delete', data: {
      if (ids != null) 'ids': ids,
    });
  }

  @override
  Future<AttachmentItem> uploadAttachment({
    required List<int> fileBytes,
    required String fileName,
    required String documentCategory,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'document_category': documentCategory,
    });

    final response = await apiClient.post(ApiConstants.uploadAttachment, data: formData);
    final json = response as Map<String, dynamic>;
    return AttachmentItem(
      id: (json['id'] != null && json['id'].toString().isNotEmpty)
          ? json['id'].toString()
          : 'att_${DateTime.now().microsecondsSinceEpoch}',
      fileName: json['file_name'].toString(),
      fileType: json['file_type'].toString(),
      sizeBytes: json['size_bytes'] as int,
      fileUrl: json['file_url'].toString(),
      uploadedBy: json['uploaded_by']?.toString() ?? 'Student',
      uploadedAt: json['uploaded_at'] != null ? DateTime.parse(json['uploaded_at'].toString()) : DateTime.now(),
      documentCategory: json['document_category']?.toString() ?? documentCategory,
    );
  }

  OdRequest _mapJsonToOdRequest(Map<String, dynamic> json) {
    final statusStr = json['status'].toString();
    final status = OdStatus.fromApiString(statusStr);

    final attachmentsList = (json['attachments'] as List? ?? []).map((att) {
      return AttachmentItem(
        id: att['id']?.toString() ?? '',
        fileName: att['file_name'].toString(),
        fileType: att['file_type'].toString(),
        sizeBytes: att['size_bytes'] as int,
        fileUrl: att['file_url'].toString(),
        uploadedBy: att['uploaded_by'].toString(),
        uploadedAt: DateTime.parse(att['uploaded_at'].toString()),
        documentCategory: att['document_category']?.toString() ?? 'pre_approval_support',
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
      studentName: json['student_name']?.toString() ?? '',
      registerNumber: json['register_number']?.toString() ?? '',
      program: json['program']?.toString(),
      yearSection: json['year_section']?.toString(),
      studentEmail: json['student_email']?.toString(),
      reason: json['reason'].toString(),
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      durationDays: json['duration_days'] as int,
      purpose: json['purpose'].toString(),
      venue: json['venue'].toString(),
      organizer: json['organizer'].toString(),
      additionalNotes: json['additional_notes']?.toString(),
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble(),
      residenceType: json['residence_type']?.toString(),
      parentConsentUrl: json['parent_consent_url']?.toString(),
      facultyAdvisorId: json['faculty_id']?.toString() ?? '',
      facultyAdvisorName: json['faculty_advisor_name']?.toString() ?? '',
      facultyApprovalTime: json['faculty_approval_time'] != null
          ? DateTime.parse(json['faculty_approval_time'].toString())
          : null,
      status: status,
      completionSummary: json['completion_summary']?.toString(),
      completionSubmittedAt: json['completion_submitted_at'] != null
          ? DateTime.parse(json['completion_submitted_at'].toString())
          : null,
      completionVerifiedAt: json['completion_verified_at'] != null
          ? DateTime.parse(json['completion_verified_at'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
      attachments: attachmentsList,
      timeline: timelineList,
      comments: commentsList,
    );
  }
}
