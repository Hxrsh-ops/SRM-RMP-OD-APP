import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';
import '../buttons/app_primary_button.dart';

class AppErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onDismiss;

  const AppErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.buttonLabel = 'Dismiss',
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String buttonLabel = 'Dismiss',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AppErrorDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
      backgroundColor: theme.colorScheme.surface,
      titlePadding: const EdgeInsets.all(AppSpacing.xl),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      actionsPadding: const EdgeInsets.all(AppSpacing.xl),
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        AppPrimaryButton(
          label: buttonLabel,
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
