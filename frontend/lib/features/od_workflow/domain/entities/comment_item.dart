class CommentItem {
  final String id;
  final String authorName;
  final String authorRole;
  final String text;
  final DateTime timestamp;

  const CommentItem({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.text,
    required this.timestamp,
  });
}
