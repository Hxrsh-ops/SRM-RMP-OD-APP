import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';
import '../buttons/app_destructive_button.dart';
import '../buttons/app_primary_button.dart';
import '../buttons/app_secondary_button.dart';

class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
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
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: cancelLabel,
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (isDestructive)
          AppDestructiveButton(
            label: confirmLabel,
            onPressed: onConfirm,
          )
        else
          AppPrimaryButton(
            label: confirmLabel,
            onPressed: onConfirm,
          ),
      ],
    );
  }
}
