import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';
import '../chips/app_status_chip.dart';
import 'app_card.dart';

class AppMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final AppStatusType statusType;

  const AppMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.statusType = AppStatusType.info,
  });

  Color _getBadgeColor() {
    switch (statusType) {
      case AppStatusType.success:
      case AppStatusType.approved:
        return AppColors.success;
      case AppStatusType.warning:
      case AppStatusType.pending:
        return AppColors.warning;
      case AppStatusType.error:
      case AppStatusType.rejected:
        return AppColors.danger;
      case AppStatusType.revisionRequested:
        return AppColors.warning;
      case AppStatusType.awaitingEvidence:
      case AppStatusType.info:
        return AppColors.primaryBlue;
      case AppStatusType.evidenceReview:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: badgeColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
