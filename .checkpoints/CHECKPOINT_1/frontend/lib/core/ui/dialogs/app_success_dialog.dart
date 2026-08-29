import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';
import '../buttons/app_primary_button.dart';

class AppSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onDismiss;

  const AppSuccessDialog({
    super.key,
    this.title = 'Success',
    required this.message,
    this.buttonLabel = 'Continue',
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Success',
    required String message,
    String buttonLabel = 'Continue',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AppSuccessDialog(
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

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
      backgroundColor: theme.colorScheme.surface,
      titlePadding: const EdgeInsets.all(AppSpacing.xl),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      actionsPadding: const EdgeInsets.all(AppSpacing.xl),
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 28),
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
