class AttachmentItem {
  final String id;
  final String fileName;
  final String fileType;
  final int sizeBytes;
  final String fileUrl;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String documentCategory;

  const AttachmentItem({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.sizeBytes,
    required this.fileUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    this.documentCategory = 'pre_approval_support',
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
