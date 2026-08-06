import 'dart:async';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/od_request.dart';
import '../../domain/entities/od_status.dart';
import '../../domain/entities/timeline_step.dart';
import '../../domain/repositories/workflow_repository.dart';

class MockWorkflowRepository implements WorkflowRepository {
  final List<OdRequest> _requests = [];
  final List<NotificationItem> _notifications = [];
  final _streamController = StreamController<List<OdRequest>>.broadcast();

  MockWorkflowRepository() {
    _seedMockData();
  }

  Stream<List<OdRequest>> get watchRequests => _streamController.stream;

  void _notifyListeners() {
    _streamController.add(List.unmodifiable(_requests));
  }

  void _seedMockData() {
    final now = DateTime.now();

    final req1 = OdRequest(
      id: 'OD-2026-001',
      studentId: 'RA2511026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2511026020400',
      reason: 'Hackathon / Competition',
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 1)),
      durationDays: 3,
      purpose: 'Participating in National AI Hackathon 2026',
      venue: 'Tech Park Auditorium, SRM Ramapuram',
      organizer: 'Department of CSE & AI Club',
      additionalNotes: 'Team Leader for Antigravity Hackers',
      cgpa: 8.8,
      attendancePercentage: 91.5,
      residenceType: 'Hosteller',
      parentConsentUrl: 'https://example.com/parent_consent_harshanth.pdf',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B (Mock)',
      status: OdStatus.pendingFaculty,
      attachments: [
        AttachmentItem(
          id: 'ATT-1',
          fileName: 'Hackathon_Invitation_Letter.pdf',
          fileType: 'pdf',
          sizeBytes: 1024 * 450,
          fileUrl: 'https://example.com/att1.pdf',
          uploadedBy: 'K.M. Harshanth',
          uploadedAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      timeline: [
        TimelineStep(
          id: 'TS-1',
          title: 'Request Submitted',
          actorName: 'K.M. Harshanth',
          actorRole: 'Student',
          status: OdStatus.submitted,
          timestamp: now.subtract(const Duration(days: 2)),
          note: 'Submitted 3-day OD request for National Hackathon',
        ),
        TimelineStep(
          id: 'TS-2',
          title: 'Assigned to Faculty Advisor',
          actorName: 'Dr. Karthik B (Mock)',
          actorRole: 'Faculty Advisor',
          status: OdStatus.pendingFaculty,
          timestamp: now.subtract(const Duration(days: 2)),
          note: 'Awaiting Faculty Advisor review',
        ),
      ],
      comments: [],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    _requests.add(req1);
  }

  @override
  Future<List<OdRequest>> getMyRequests({bool includeHistory = false}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_requests);
  }

  @override
  Future<OdRequest> getRequestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests.firstWhere((r) => r.id == id);
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
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final newId = 'OD-2026-00${_requests.length + 1}';

    final newRequest = OdRequest(
      id: newId,
      studentId: studentId,
      studentName: studentName,
      registerNumber: registerNumber,
      reason: reason,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      purpose: purpose,
      venue: venue,
      organizer: organizer,
      additionalNotes: additionalNotes,
      cgpa: cgpa,
      attendancePercentage: attendancePercentage,
      residenceType: residenceType ?? 'Day Scholar',
      parentConsentUrl: parentConsentUrl,
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B (Mock)',
      status: OdStatus.pendingFaculty,
      attachments: attachments ?? [],
      timeline: [
        TimelineStep(
          id: 'TS-${now.millisecondsSinceEpoch}-1',
          title: 'Request Submitted',
          actorName: studentName,
          actorRole: 'Student',
          status: OdStatus.submitted,
          timestamp: now,
          note: 'Submitted On Duty request for $reason',
        ),
      ],
      comments: [],
      createdAt: now,
    );

    _requests.insert(0, newRequest);
    _notifyListeners();
    return newRequest;
  }

  @override
  Future<OdRequest> facultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request not found');

    final req = _requests[index];
    final newStatus = req.status == OdStatus.pendingEvidenceFaculty
        ? (approve ? OdStatus.pendingEvidenceCoordinator : OdStatus.evidenceRevisionRequested)
        : (approve ? OdStatus.pendingCoordinator : OdStatus.facultyRejected);

    _requests[index] = req.copyWith(status: newStatus);
    _notifyListeners();
    return _requests[index];
  }

  @override
  Future<OdRequest> coordinatorAction({
    required String requestId,
    required String coordinatorId,
    required String coordinatorName,
    required bool approve,
    bool returnForCorrection = false,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request not found');

    final req = _requests[index];
    final newStatus = req.status == OdStatus.pendingEvidenceCoordinator
        ? (approve ? OdStatus.completed : OdStatus.evidenceRevisionRequested)
        : (returnForCorrection ? OdStatus.revisionRequested : (approve ? OdStatus.approvedAwaitingEvidence : OdStatus.rejected));

    _requests[index] = req.copyWith(status: newStatus);
    _notifyListeners();
    return _requests[index];
  }

  @override
  Future<OdRequest> submitCompletionEvidence({
    required String requestId,
    required String completionSummary,
    required List<List<int>> filesBytes,
    required List<String> fileNames,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request not found');

    final req = _requests[index];
    final updated = req.copyWith(
      status: OdStatus.pendingEvidenceFaculty,
      completionSummary: completionSummary,
      completionSubmittedAt: DateTime.now(),
    );
    _requests[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<Map<String, int>> getCoordinatorAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'pending_coordinator_count': _requests.where((r) => r.status == OdStatus.pendingCoordinator).length,
      'approved_awaiting_evidence_count': _requests.where((r) => r.status == OdStatus.approvedAwaitingEvidence).length,
      'pending_evidence_coordinator_count': _requests.where((r) => r.status == OdStatus.pendingEvidenceCoordinator).length,
      'completed_count': _requests.where((r) => r.status == OdStatus.completed).length,
      'total_submissions_count': _requests.length,
    };
  }

  @override
  Future<List<NotificationItem>> getNotifications(String recipientId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notifications.where((n) => n.recipientId == recipientId).toList();
  }

  @override
  Future<void> markNotificationsRead(String recipientId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientId == recipientId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<AttachmentItem> uploadAttachment({
    required List<int> fileBytes,
    required String fileName,
    required String documentCategory,
  }) async {
    final now = DateTime.now();
    final ext = fileName.contains('.') ? fileName.split('.').last : 'pdf';
    return AttachmentItem(
      id: 'ATT-${now.millisecondsSinceEpoch}',
      fileName: fileName,
      fileType: ext,
      sizeBytes: fileBytes.length,
      fileUrl: 'http://127.0.0.1:8000/uploads/$fileName',
      uploadedBy: 'Student',
      uploadedAt: now,
    );
  }
}
