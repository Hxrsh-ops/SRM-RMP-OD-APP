import 'dart:async';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/comment_item.dart';
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
      studentId: 'RA2510026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2510026020400',
      reason: 'Hackathon / Competition',
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 1)),
      durationDays: 3,
      purpose: 'Participating in National AI Hackathon 2026',
      venue: 'Tech Park Auditorium, SRM Ramapuram',
      organizer: 'Department of CSE & AI Club',
      additionalNotes: 'Team Leader for Antigravity Hackers',
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

    final req2 = OdRequest(
      id: 'OD-2026-002',
      studentId: 'RA2510026020400',
      studentName: 'K.M. Harshanth',
      registerNumber: 'RA2510026020400',
      reason: 'Sports Event',
      startDate: now.add(const Duration(days: 5)),
      endDate: now.add(const Duration(days: 6)),
      durationDays: 2,
      purpose: 'Inter-College Basketball Championship',
      venue: 'Indoor Sports Complex, Main Campus',
      organizer: 'SRM Sports Council',
      additionalNotes: 'Selected for University Varsity Team',
      facultyAdvisorId: 'FA1001',
      facultyAdvisorName: 'Dr. Karthik B (Mock)',
      status: OdStatus.pendingCoordinator,
      attachments: [],
      timeline: [
        TimelineStep(
          id: 'TS-3',
          title: 'Request Submitted',
          actorName: 'K.M. Harshanth',
          actorRole: 'Student',
          status: OdStatus.submitted,
          timestamp: now.subtract(const Duration(days: 4)),
        ),
        TimelineStep(
          id: 'TS-4',
          title: 'Faculty Approved',
          actorName: 'Dr. Karthik B (Mock)',
          actorRole: 'Faculty Advisor',
          status: OdStatus.facultyApproved,
          timestamp: now.subtract(const Duration(days: 1)),
          note: 'Verified student sports participation details.',
        ),
        TimelineStep(
          id: 'TS-5',
          title: 'Pending Coordinator Sign-Off',
          actorName: 'Prof. Ramesh Kumar',
          actorRole: 'Coordinator',
          status: OdStatus.pendingCoordinator,
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ],
      comments: [
        CommentItem(
          id: 'C-1',
          authorName: 'Dr. Karthik B (Mock)',
          authorRole: 'Faculty Advisor',
          text: 'Approved. Attendance requirements verified.',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ],
      createdAt: now.subtract(const Duration(days: 4)),
    );

    _requests.addAll([req1, req2]);

    _notifications.addAll([
      NotificationItem(
        id: 'N-1',
        recipientId: 'RA2510026020400',
        title: 'OD Request Created',
        message: 'Your OD request for National AI Hackathon 2026 has been submitted.',
        timestamp: now.subtract(const Duration(days: 2)),
        requestId: 'OD-2026-001',
      ),
      NotificationItem(
        id: 'N-2',
        recipientId: 'FA1001',
        title: 'New OD Request Assigned',
        message: 'Student K.M. Harshanth submitted OD request OD-2026-001 for your approval.',
        timestamp: now.subtract(const Duration(days: 2)),
        requestId: 'OD-2026-001',
      ),
      NotificationItem(
        id: 'N-3',
        recipientId: 'CO1001',
        title: 'Faculty Approved OD Request',
        message: 'Dr. Karthik B (Mock) approved OD-2026-002. Awaiting final coordinator sign-off.',
        timestamp: now.subtract(const Duration(days: 1)),
        requestId: 'OD-2026-002',
      ),
    ]);
  }

  @override
  Future<List<OdRequest>> getAllRequests() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_requests);
  }

  @override
  Future<List<OdRequest>> getStudentRequests(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.where((r) => r.studentId == studentId || r.registerNumber == studentId).toList();
  }

  @override
  Future<List<OdRequest>> getFacultyPendingRequests(String facultyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.submitted).toList();
  }

  @override
  Future<List<OdRequest>> getCoordinatorPendingRequests() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.where((r) => r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved).toList();
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
        TimelineStep(
          id: 'TS-${now.millisecondsSinceEpoch}-2',
          title: 'Assigned to Faculty Advisor',
          actorName: 'Dr. Karthik B (Mock)',
          actorRole: 'Faculty Advisor',
          status: OdStatus.pendingFaculty,
          timestamp: now,
        ),
      ],
      comments: [],
      createdAt: now,
    );

    _requests.insert(0, newRequest);

    // Dynamic Notifications
    _notifications.insert(
      0,
      NotificationItem(
        id: 'N-${now.millisecondsSinceEpoch}-1',
        recipientId: studentId,
        title: 'OD Request Submitted',
        message: 'Your OD request for $reason has been submitted successfully.',
        timestamp: now,
        requestId: newId,
      ),
    );

    _notifications.insert(
      0,
      NotificationItem(
        id: 'N-${now.millisecondsSinceEpoch}-2',
        recipientId: 'FA1001',
        title: 'New OD Request Assigned',
        message: '$studentName submitted OD request $newId for $reason.',
        timestamp: now,
        requestId: newId,
      ),
    );

    _notifyListeners();
    return newRequest;
  }

  @override
  Future<void> facultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _requests[index];
    final now = DateTime.now();
    final newStatus = approve ? OdStatus.pendingCoordinator : OdStatus.facultyRejected;

    final updatedTimeline = List<TimelineStep>.from(req.timeline);
    updatedTimeline.add(
      TimelineStep(
        id: 'TS-${now.millisecondsSinceEpoch}',
        title: approve ? 'Faculty Advisor Approved' : 'Faculty Advisor Rejected',
        actorName: facultyName,
        actorRole: 'Faculty Advisor',
        status: newStatus,
        timestamp: now,
        note: comment ?? (approve ? 'Approved by Faculty Advisor' : 'Rejected by Faculty Advisor'),
      ),
    );

    final updatedComments = List<CommentItem>.from(req.comments);
    if (comment != null && comment.trim().isNotEmpty) {
      updatedComments.add(
        CommentItem(
          id: 'C-${now.millisecondsSinceEpoch}',
          authorName: facultyName,
          authorRole: 'Faculty Advisor',
          text: comment.trim(),
          timestamp: now,
        ),
      );
    }

    _requests[index] = req.copyWith(
      status: newStatus,
      timeline: updatedTimeline,
      comments: updatedComments,
    );

    // Dynamic notifications for Student & Coordinator
    _notifications.insert(
      0,
      NotificationItem(
        id: 'N-${now.millisecondsSinceEpoch}-S',
        recipientId: req.studentId,
        title: approve ? 'Faculty Approved OD' : 'Faculty Rejected OD',
        message: approve
            ? 'Faculty Advisor $facultyName approved your request $requestId. Pending Coordinator.'
            : 'Faculty Advisor $facultyName rejected your request $requestId.',
        timestamp: now,
        requestId: requestId,
      ),
    );

    if (approve) {
      _notifications.insert(
        0,
        NotificationItem(
          id: 'N-${now.millisecondsSinceEpoch}-C',
          recipientId: 'CO1001',
          title: 'OD Awaiting Coordinator Sign-Off',
          message: 'Faculty Advisor $facultyName approved request $requestId for ${req.studentName}.',
          timestamp: now,
          requestId: requestId,
        ),
      );
    }

    _notifyListeners();
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
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _requests[index];
    final now = DateTime.now();
    final OdStatus newStatus;
    if (returnForCorrection) {
      newStatus = OdStatus.revisionRequested;
    } else if (approve) {
      newStatus = OdStatus.completed;
    } else {
      newStatus = OdStatus.rejected;
    }

    final updatedTimeline = List<TimelineStep>.from(req.timeline);
    updatedTimeline.add(
      TimelineStep(
        id: 'TS-${now.millisecondsSinceEpoch}',
        title: returnForCorrection
            ? 'Returned for Correction'
            : (approve ? 'Final Approval Granted' : 'Coordinator Rejected'),
        actorName: coordinatorName,
        actorRole: 'Coordinator',
        status: newStatus,
        timestamp: now,
        note: comment ?? (approve ? 'Approved by Coordinator' : 'Decision recorded'),
      ),
    );

    final updatedComments = List<CommentItem>.from(req.comments);
    if (comment != null && comment.trim().isNotEmpty) {
      updatedComments.add(
        CommentItem(
          id: 'C-${now.millisecondsSinceEpoch}',
          authorName: coordinatorName,
          authorRole: 'Coordinator',
          text: comment.trim(),
          timestamp: now,
        ),
      );
    }

    _requests[index] = req.copyWith(
      status: newStatus,
      timeline: updatedTimeline,
      comments: updatedComments,
    );

    // Push notification to Student & Faculty
    _notifications.insert(
      0,
      NotificationItem(
        id: 'N-${now.millisecondsSinceEpoch}-S',
        recipientId: req.studentId,
        title: approve ? 'OD Approved!' : (returnForCorrection ? 'OD Needs Revision' : 'OD Rejected'),
        message: 'Coordinator $coordinatorName has processed your request $requestId.',
        timestamp: now,
        requestId: requestId,
      ),
    );

    _notifyListeners();
  }

  @override
  Future<List<NotificationItem>> getNotifications(String recipientId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notifications.where((n) => n.recipientId == recipientId || n.recipientId == 'RA2510026020400').toList();
  }

  @override
  Future<void> markNotificationsRead(String recipientId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientId == recipientId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }
}
