import 'od_status.dart';

class TimelineStep {
  final String id;
  final String title;
  final String actorName;
  final String actorRole;
  final OdStatus status;
  final DateTime timestamp;
  final String? note;

  const TimelineStep({
    required this.id,
    required this.title,
    required this.actorName,
    required this.actorRole,
    required this.status,
    required this.timestamp,
    this.note,
  });
}
