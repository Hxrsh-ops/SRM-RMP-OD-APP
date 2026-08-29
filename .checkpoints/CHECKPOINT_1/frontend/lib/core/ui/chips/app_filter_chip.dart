import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = isSelected ? AppColors.primaryBlue : AppColors.surface;
    final textColor = isSelected ? Colors.white : AppColors.textPrimary;
    final borderColor = isSelected ? AppColors.primaryBlue : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRound,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.borderRound,
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
