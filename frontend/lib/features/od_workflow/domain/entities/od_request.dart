import 'attachment_item.dart';
import 'comment_item.dart';
import 'od_status.dart';
import 'timeline_step.dart';

class OdRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String registerNumber;
  final String? program;
  final String? yearSection;
  final String? studentEmail;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final String purpose;
  final String venue;
  final String organizer;
  final String? additionalNotes;
  final double? cgpa;
  final double? attendancePercentage;
  final String? residenceType;
  final String? parentConsentUrl;
  final String facultyAdvisorId;
  final String facultyAdvisorName;
  final DateTime? facultyApprovalTime;
  final OdStatus status;
  final String? completionSummary;
  final DateTime? completionSubmittedAt;
  final DateTime? completionVerifiedAt;
  final List<AttachmentItem> attachments;
  final List<TimelineStep> timeline;
  final List<CommentItem> comments;
  final DateTime createdAt;

  const OdRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    this.program,
    this.yearSection,
    this.studentEmail,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.purpose,
    required this.venue,
    required this.organizer,
    this.additionalNotes,
    this.cgpa,
    this.attendancePercentage,
    this.residenceType,
    this.parentConsentUrl,
    required this.facultyAdvisorId,
    required this.facultyAdvisorName,
    this.facultyApprovalTime,
    required this.status,
    this.completionSummary,
    this.completionSubmittedAt,
    this.completionVerifiedAt,
    required this.attachments,
    required this.timeline,
    required this.comments,
    required this.createdAt,
  });

  String get displayProgram => program ?? '—';
  String get displayYearSection => yearSection ?? '—';
  String get displayStudentEmail => studentEmail ?? '—';
  String get displayResidenceType => residenceType ?? 'Day Scholar';
  String get displayFacultyAdvisorName => facultyAdvisorName.isNotEmpty ? facultyAdvisorName : 'Faculty Advisor';

  OdRequest copyWith({
    OdStatus? status,
    String? completionSummary,
    DateTime? completionSubmittedAt,
    DateTime? completionVerifiedAt,
    List<AttachmentItem>? attachments,
    List<TimelineStep>? timeline,
    List<CommentItem>? comments,
  }) {
    return OdRequest(
      id: id,
      studentId: studentId,
      studentName: studentName,
      registerNumber: registerNumber,
      program: program,
      yearSection: yearSection,
      studentEmail: studentEmail,
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
      residenceType: residenceType,
      parentConsentUrl: parentConsentUrl,
      facultyAdvisorId: facultyAdvisorId,
      facultyAdvisorName: facultyAdvisorName,
      facultyApprovalTime: facultyApprovalTime,
      status: status ?? this.status,
      completionSummary: completionSummary ?? this.completionSummary,
      completionSubmittedAt: completionSubmittedAt ?? this.completionSubmittedAt,
      completionVerifiedAt: completionVerifiedAt ?? this.completionVerifiedAt,
      attachments: attachments ?? this.attachments,
      timeline: timeline ?? this.timeline,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }

  bool get isEscalatedToDean {
    return timeline.any((t) {
      final title = t.title.toLowerCase();
      final note = (t.note ?? '').toLowerCase();
      return title.contains('escalated to dean') ||
          title.contains('escalated to executive dean') ||
          note.contains('[escalated to dean]');
    });
  }

  bool get isEscalatedToHod {
    return timeline.any((t) {
      final title = t.title.toLowerCase();
      final note = (t.note ?? '').toLowerCase();
      return title.contains('escalated to hod') ||
          title.contains('escalated to head of department') ||
          title.contains('routed to hod') ||
          note.contains('[escalated to hod]');
    });
  }

  bool get isDirectHodSubmission {
    return timeline.any((t) {
      final title = t.title.toLowerCase();
      final note = (t.note ?? '').toLowerCase();
      return title.contains('directly for head of department') ||
          title.contains('direct hod') ||
          title.contains('routed to head of department') ||
          title.contains('forwarded for hod') ||
          title.contains('forwarded for head of department') ||
          title.contains('hod review') ||
          note.contains('directly for head of department') ||
          note.contains('direct hod') ||
          note.contains('forwarded for hod') ||
          note.contains('forwarded for head of department') ||
          note.contains('head of department (hod) review') ||
          note.contains('head of department (hod) approval') ||
          note.contains('hod review');
    });
  }

  String get statusDisplayLabel {
    if (status == OdStatus.pendingCoordinator) {
      if (isEscalatedToDean) return 'Pending Dean';
      if (isEscalatedToHod || isDirectHodSubmission) return 'Pending HOD';
      return 'Pending Coordinator';
    }
    if (status == OdStatus.pendingEvidenceCoordinator) {
      if (isEscalatedToDean) return 'Pending Dean Proof';
      if (isEscalatedToHod) return 'Pending HOD Proof';
      return 'Pending Proof Review';
    }
    if (status == OdStatus.pendingFaculty) return 'Pending FA Approval';
    return status.displayName;
  }
}
