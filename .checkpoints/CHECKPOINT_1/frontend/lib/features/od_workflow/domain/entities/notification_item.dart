class NotificationItem {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? requestId;

  const NotificationItem({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.requestId,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      recipientId: recipientId,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      requestId: requestId,
    );
  }
}
