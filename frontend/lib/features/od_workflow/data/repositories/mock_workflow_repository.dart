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
      comments: const [],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    _requests.add(req1);

    // Completed 1
    _requests.add(OdRequest(
      id: 'OD-2026-002',
      studentId: 'RA2511026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2511026020400',
      reason: 'IEEE International Conference',
      startDate: now.subtract(const Duration(days: 25)),
      endDate: now.subtract(const Duration(days: 23)),
      durationDays: 3,
      purpose: 'Oral Research Paper Presentation on LLM Benchmarks',
      venue: 'IIT Madras Research Park',
      organizer: 'IEEE Computer Society',
      cgpa: 8.8,
      attendancePercentage: 91.5,
      residenceType: 'Hosteller',
      parentConsentUrl: 'https://example.com/parent_consent.pdf',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B',
      status: OdStatus.completed,
      attachments: const [],
      timeline: const [],
      comments: const [],
      createdAt: now.subtract(const Duration(days: 25)),
    ));

    // Completed 2
    _requests.add(OdRequest(
      id: 'OD-2026-003',
      studentId: 'RA2511026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2511026020400',
      reason: 'Smart India Hackathon 2026',
      startDate: now.subtract(const Duration(days: 45)),
      endDate: now.subtract(const Duration(days: 43)),
      durationDays: 3,
      purpose: 'Grand Finale Problem Statement Solution',
      venue: 'Tech Hub Hyderabad',
      organizer: 'Ministry of Education Innovation Cell',
      cgpa: 8.8,
      attendancePercentage: 91.5,
      residenceType: 'Hosteller',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B',
      status: OdStatus.completed,
      attachments: const [],
      timeline: const [],
      comments: const [],
      createdAt: now.subtract(const Duration(days: 45)),
    ));

    // Completed 3
    _requests.add(OdRequest(
      id: 'OD-2026-004',
      studentId: 'RA2511026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2511026020400',
      reason: 'State Level Technical Symposium',
      startDate: now.subtract(const Duration(days: 60)),
      endDate: now.subtract(const Duration(days: 59)),
      durationDays: 2,
      purpose: 'Coding & Debugging Challenge',
      venue: 'Anna University Campus',
      organizer: 'Dept of IT',
      cgpa: 8.8,
      attendancePercentage: 91.5,
      residenceType: 'Day Scholar',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B',
      status: OdStatus.completed,
      attachments: const [],
      timeline: const [],
      comments: const [],
      createdAt: now.subtract(const Duration(days: 60)),
    ));

    // Completed 4
    _requests.add(OdRequest(
      id: 'OD-2026-005',
      studentId: 'RA2511026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2511026020400',
      reason: 'Inter-University Robotics Meet',
      startDate: now.subtract(const Duration(days: 80)),
      endDate: now.subtract(const Duration(days: 79)),
      durationDays: 2,
      purpose: 'Autonomous Rover Demonstration',
      venue: 'PSG Tech Coimbatore',
      organizer: 'Robotics Association',
      cgpa: 8.8,
      attendancePercentage: 91.5,
      residenceType: 'Day Scholar',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B',
      status: OdStatus.completed,
      attachments: const [],
      timeline: const [],
      comments: const [],
      createdAt: now.subtract(const Duration(days: 80)),
    ));

    // Rejected 1
    _requests.add(OdRequest(
      id: 'OD-2026-006',
      studentId: 'RA2511026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2511026020400',
      reason: 'Local Cultural Fest',
      startDate: now.subtract(const Duration(days: 90)),
      endDate: now.subtract(const Duration(days: 89)),
      durationDays: 2,
      purpose: 'Music Band Performance',
      venue: 'City Convention Center',
      organizer: 'Cultural Forum',
      cgpa: 8.8,
      attendancePercentage: 91.5,
      residenceType: 'Day Scholar',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B',
      status: OdStatus.rejected,
      attachments: const [],
      timeline: const [],
      comments: const [],
      createdAt: now.subtract(const Duration(days: 90)),
    ));

    // Faculty Pending 2
    _requests.add(OdRequest(
      id: 'OD-2026-007',
      studentId: 'RA2511026020405',
      studentName: 'Ananya Sharma',
      registerNumber: 'RA2511026020405',
      reason: 'ACM Student Research Competition',
      startDate: now.add(const Duration(days: 3)),
      endDate: now.add(const Duration(days: 5)),
      durationDays: 3,
      purpose: 'Presenting Poster on Cloud Telemetry',
      venue: 'Vellore Institute of Technology',
      organizer: 'ACM Chapter',
      cgpa: 9.1,
      attendancePercentage: 94.0,
      residenceType: 'Day Scholar',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B',
      status: OdStatus.pendingFaculty,
      attachments: const [],
      timeline: const [],
      comments: const [],
      createdAt: now.subtract(const Duration(hours: 4)),
    ));

    // Coordinator Pending 1
    _requests.add(OdRequest(
      id: 'OD-2026-008',
      studentId: 'RA2511026020412',
      studentName: 'Rohan Verma',
      registerNumber: 'RA2511026020412',
      reason: 'National Cyber Security Summit',
      startDate: now.add(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 4)),
      durationDays: 3,
      purpose: 'CTF Competition Finals',
      venue: 'IIIT Hyderabad',
      organizer: 'C-DAC',
      cgpa: 8.4,
      attendancePercentage: 87.0,
      residenceType: 'Hosteller',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B',
      status: OdStatus.pendingCoordinator,
      attachments: const [],
      timeline: const [],
      comments: const [],
      createdAt: now.subtract(const Duration(hours: 12)),
    ));
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
    await Future.delayed(const Duration(milliseconds: 300));
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
    await Future.delayed(const Duration(milliseconds: 300));
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
    await Future.delayed(const Duration(milliseconds: 400));
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
    await Future.delayed(const Duration(milliseconds: 300));
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
    await Future.delayed(const Duration(milliseconds: 100));
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
