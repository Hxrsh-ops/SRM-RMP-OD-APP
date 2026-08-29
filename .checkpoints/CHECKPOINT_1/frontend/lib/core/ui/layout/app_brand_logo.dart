import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool isDarkBackground;

  const AppBrandLogo({
    super.key,
    this.size = 48.0,
    this.showWordmark = true,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final logoBadge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDarkBackground ? AppColors.accentYellow : AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.shield_rounded,
          size: size * 0.58,
          color: isDarkBackground ? AppColors.primaryBlue : AppColors.accentYellow,
        ),
      ),
    );

    if (!showWordmark) return logoBadge;

    final primaryTextColor = isDarkBackground ? Colors.white : AppColors.primaryBlue;
    final secondaryTextColor = isDarkBackground ? AppColors.accentYellow : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoBadge,
        const SizedBox(width: AppSpacing.md),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SRM RMP',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: primaryTextColor,
              ),
            ),
            Text(
              'ON DUTY WORKFLOW',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
