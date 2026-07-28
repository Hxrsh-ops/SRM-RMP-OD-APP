import 'package:flutter/material.dart';
import '../../theme/custom_theme_extensions.dart';
import '../../theme/tokens/theme_tokens.dart';

enum AppStatusType {
  success,
  warning,
  error,
  info,
  pending,
  approved,
  rejected,
}

class AppStatusChip extends StatelessWidget {
  final String label;
  final AppStatusType statusType;
  final IconData? customIcon;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.statusType,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusExtension = theme.extension<StatusColorsExtension>();

    Color baseColor;
    IconData defaultIcon;

    switch (statusType) {
      case AppStatusType.success:
        baseColor = const Color(0xFF16A34A);
        defaultIcon = Icons.check_circle_outline_rounded;
        break;
      case AppStatusType.warning:
        baseColor = const Color(0xFFEA580C);
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case AppStatusType.error:
        baseColor = theme.colorScheme.error;
        defaultIcon = Icons.error_outline_rounded;
        break;
      case AppStatusType.info:
        baseColor = const Color(0xFF0284C7);
        defaultIcon = Icons.info_outline_rounded;
        break;
      case AppStatusType.pending:
        baseColor = statusExtension?.pending ?? const Color(0xFFD97706);
        defaultIcon = Icons.hourglass_empty_rounded;
        break;
      case AppStatusType.approved:
        baseColor = statusExtension?.approved ?? const Color(0xFF16A34A);
        defaultIcon = Icons.verified_outlined;
        break;
      case AppStatusType.rejected:
        baseColor = statusExtension?.rejected ?? const Color(0xFFDC2626);
        defaultIcon = Icons.cancel_outlined;
        break;
    }

    final backgroundColor = baseColor.withValues(alpha: 0.12);
    final iconData = customIcon ?? defaultIcon;

    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 14.0, color: baseColor),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: baseColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
