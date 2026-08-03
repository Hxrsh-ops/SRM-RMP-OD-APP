import 'attachment_item.dart';
import 'comment_item.dart';
import 'od_status.dart';
import 'timeline_step.dart';

class OdRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String registerNumber;
  final String program;
  final String yearSection;
  final String studentEmail;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final String purpose;
  final String venue;
  final String organizer;
  final String? additionalNotes;
  final double cgpa;
  final double attendancePercentage;
  final String residenceType;
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
    this.program = 'B.Tech CSE (AI & ML)',
    this.yearSection = '2nd Year - Sec G',
    this.studentEmail = 'hk7793@srmist.edu.in',
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.purpose,
    required this.venue,
    required this.organizer,
    this.additionalNotes,
    this.cgpa = 8.5,
    this.attendancePercentage = 88.0,
    this.residenceType = 'Day Scholar',
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
}
