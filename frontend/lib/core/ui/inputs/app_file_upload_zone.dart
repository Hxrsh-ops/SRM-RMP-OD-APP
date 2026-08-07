import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppFileUploadZone extends StatelessWidget {
  final List<PlatformFile> selectedFiles;
  final Function(List<PlatformFile>) onFilesPicked;
  final Function(PlatformFile) onFileRemoved;
  final bool isUploading;
  final double uploadProgress; // 0.0 to 1.0
  final String? errorMessage;
  final List<String> allowedExtensions;
  final int maxFileSizeMb;

  const AppFileUploadZone({
    super.key,
    required this.selectedFiles,
    required this.onFilesPicked,
    required this.onFileRemoved,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg'],
    this.maxFileSizeMb = 5,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropzone area / Picker trigger
        InkWell(
          onTap: isUploading
              ? null
              : () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: allowedExtensions,
                    withData: true,
                  );
                  if (result != null) {
                    onFilesPicked(result.files);
                  }
                },
          borderRadius: AppRadius.borderMd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: AppRadius.borderMd,
              border: Border.all(
                color: isUploading ? AppColors.primaryBlue : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: isUploading ? AppColors.primaryBlue : AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap to select & upload completion proof documents',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'Supported: ${allowedExtensions.map((e) => e.toUpperCase()).join(", ")} • Max size: ${maxFileSizeMb}MB',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],

        // Selected Files List
        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Selected Documents:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          ...selectedFiles.map(
            (file) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, size: 18, color: AppColors.primaryBlue),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatSize(file.size),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!isUploading)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                      onPressed: () => onFileRemoved(file),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    )
                  else
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                    ),
                ],
              ),
            ),
          ),
        ],

        // Upload progress indicator animation
        if (isUploading) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: uploadProgress > 0 ? uploadProgress : null,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Uploading document package...',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              if (uploadProgress > 0)
                Text(
                  '${(uploadProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
