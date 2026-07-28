import 'attachment_item.dart';
import 'comment_item.dart';
import 'od_status.dart';
import 'timeline_step.dart';

class OdRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String registerNumber;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final String purpose;
  final String venue;
  final String organizer;
  final String? additionalNotes;
  final String facultyAdvisorId;
  final String facultyAdvisorName;
  final OdStatus status;
  final List<AttachmentItem> attachments;
  final List<TimelineStep> timeline;
  final List<CommentItem> comments;
  final DateTime createdAt;

  const OdRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.purpose,
    required this.venue,
    required this.organizer,
    this.additionalNotes,
    required this.facultyAdvisorId,
    required this.facultyAdvisorName,
    required this.status,
    required this.attachments,
    required this.timeline,
    required this.comments,
    required this.createdAt,
  });

  OdRequest copyWith({
    OdStatus? status,
    List<AttachmentItem>? attachments,
    List<TimelineStep>? timeline,
    List<CommentItem>? comments,
  }) {
    return OdRequest(
      id: id,
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
      facultyAdvisorId: facultyAdvisorId,
      facultyAdvisorName: facultyAdvisorName,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      timeline: timeline ?? this.timeline,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }
}
