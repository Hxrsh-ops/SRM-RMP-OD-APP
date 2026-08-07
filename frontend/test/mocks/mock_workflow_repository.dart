import 'dart:async';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/entities/attachment_item.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/entities/notification_item.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/entities/od_request.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/entities/od_status.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/entities/timeline_step.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/repositories/workflow_repository.dart';

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
      comments: const [],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    _requests.add(req1);
  }

  @override
  Future<List<OdRequest>> getMyRequests({bool includeHistory = false}) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return List.unmodifiable(_requests);
  }

  @override
  Future<OdRequest> getRequestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 10));
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
    await Future.delayed(const Duration(milliseconds: 10));
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
      cgpa: cgpa ?? 8.5,
      attendancePercentage: attendancePercentage ?? 88.0,
      residenceType: residenceType ?? 'Day Scholar',
      parentConsentUrl: parentConsentUrl,
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B (Mock)',
      status: OdStatus.pendingFaculty,
      attachments: attachments ?? [],
      timeline: [
        TimelineStep(
          id: 'TS-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Request Submitted',
          actorName: studentName,
          actorRole: 'Student',
          status: OdStatus.submitted,
          timestamp: now,
          note: 'Submitted On Duty application',
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
    await Future.delayed(const Duration(milliseconds: 10));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request not found');

    final req = _requests[index];
    final isEvidence = req.status == OdStatus.pendingEvidenceFaculty;
    final newStatus = approve
        ? (isEvidence ? OdStatus.pendingEvidenceCoordinator : OdStatus.pendingCoordinator)
        : (isEvidence ? OdStatus.evidenceRevisionRequested : OdStatus.facultyRejected);

    final updatedTimeline = List<TimelineStep>.from(req.timeline)
      ..add(TimelineStep(
        id: 'TS-${DateTime.now().millisecondsSinceEpoch}',
        title: approve ? (isEvidence ? 'Faculty Verified Evidence' : 'Faculty Advisor Approved') : (isEvidence ? 'Evidence Revision Requested' : 'Faculty Rejected'),
        actorName: facultyName,
        actorRole: 'Faculty Advisor',
        status: newStatus,
        timestamp: DateTime.now(),
        note: comment ?? (approve ? 'Approved' : 'Rejected'),
      ));

    final updated = req.copyWith(
      status: newStatus,
      timeline: updatedTimeline,
    );

    _requests[index] = updated;
    _notifyListeners();
    return updated;
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
    await Future.delayed(const Duration(milliseconds: 10));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request not found');

    final req = _requests[index];
    final isEvidence = req.status == OdStatus.pendingEvidenceCoordinator;

    OdStatus newStatus;
    if (isEvidence) {
      newStatus = approve ? OdStatus.completed : OdStatus.evidenceRevisionRequested;
    } else {
      if (returnForCorrection) {
        newStatus = OdStatus.revisionRequested;
      } else {
        newStatus = approve ? OdStatus.approvedAwaitingEvidence : OdStatus.rejected;
      }
    }

    final updatedTimeline = List<TimelineStep>.from(req.timeline)
      ..add(TimelineStep(
        id: 'TS-${DateTime.now().millisecondsSinceEpoch}',
        title: approve ? (isEvidence ? 'Completion Verified & OD Granted' : 'Coordinator Approved') : (returnForCorrection ? 'Returned for Correction' : 'Coordinator Rejected'),
        actorName: coordinatorName,
        actorRole: 'Coordinator',
        status: newStatus,
        timestamp: DateTime.now(),
        note: comment ?? (approve ? 'Approved' : 'Rejected'),
      ));

    final updated = req.copyWith(
      status: newStatus,
      timeline: updatedTimeline,
    );

    _requests[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<OdRequest> submitCompletionEvidence({
    required String requestId,
    required String completionSummary,
    required List<List<int>> filesBytes,
    required List<String> fileNames,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request not found');

    final req = _requests[index];
    final newAttachments = List<AttachmentItem>.from(req.attachments);

    for (int i = 0; i < fileNames.length; i++) {
      newAttachments.add(AttachmentItem(
        id: 'ATT-${DateTime.now().millisecondsSinceEpoch}-$i',
        fileName: fileNames[i],
        fileType: fileNames[i].split('.').last,
        sizeBytes: filesBytes[i].length,
        fileUrl: 'https://example.com/${fileNames[i]}',
        uploadedBy: req.studentName,
        uploadedAt: DateTime.now(),
        documentCategory: 'completion_evidence',
      ));
    }

    final updatedTimeline = List<TimelineStep>.from(req.timeline)
      ..add(TimelineStep(
        id: 'TS-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Completion Evidence Submitted',
        actorName: req.studentName,
        actorRole: 'Student',
        status: OdStatus.pendingEvidenceFaculty,
        timestamp: DateTime.now(),
        note: 'Uploaded completion proof & summary',
      ));

    final updated = req.copyWith(
      status: OdStatus.pendingEvidenceFaculty,
      completionSummary: completionSummary,
      completionSubmittedAt: DateTime.now(),
      attachments: newAttachments,
      timeline: updatedTimeline,
    );

    _requests[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<AttachmentItem> uploadAttachment({
    required List<int> fileBytes,
    required String fileName,
    required String documentCategory,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return AttachmentItem(
      id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      fileType: fileName.split('.').last,
      sizeBytes: fileBytes.length,
      fileUrl: 'https://example.com/uploads/$fileName',
      uploadedBy: 'User',
      uploadedAt: DateTime.now(),
      documentCategory: documentCategory,
    );
  }

  @override
  Future<List<NotificationItem>> getNotifications(String recipientId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return List.unmodifiable(_notifications.where((n) => n.recipientId == recipientId).toList());
  }

  @override
  Future<void> markNotificationsRead(String recipientId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientId == recipientId) {
        _notifications[i] = NotificationItem(
          id: _notifications[i].id,
          recipientId: recipientId,
          title: _notifications[i].title,
          message: _notifications[i].message,
          isRead: true,
          timestamp: _notifications[i].timestamp,
          requestId: _notifications[i].requestId,
        );
      }
    }
  }

  @override
  Future<Map<String, int>> getCoordinatorAnalytics() async {
    final pendingCoord = _requests.where((r) => r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved).length;
    final awaitingProof = _requests.where((r) => r.status == OdStatus.approvedAwaitingEvidence).length;
    final pendingEvidence = _requests.where((r) => r.status == OdStatus.pendingEvidenceCoordinator).length;
    final completed = _requests.where((r) => r.status == OdStatus.completed).length;

    return {
      "pending_coordinator_count": pendingCoord,
      "approved_awaiting_evidence_count": awaitingProof,
      "pending_evidence_coordinator_count": pendingEvidence,
      "completed_count": completed,
      "total_submissions_count": _requests.length,
    };
  }
}
