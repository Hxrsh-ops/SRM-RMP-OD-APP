import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../od_workflow/domain/entities/od_request.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';

class OdRequestTile extends StatelessWidget {
  final OdRequest request;

  const OdRequestTile({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return AppClickableCard(
      onTap: () => RequestDetailsModal.show(context, request),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.borderSm,
            ),
            child: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.id} • ${request.reason}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.studentName} (${request.registerNumber}) • ${request.durationDays} Days',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppStatusChip(label: request.status.displayName, statusType: request.status.statusType),
          if (!isMobile) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ],
      ),
    );
  }
}

class BuildIdentityCard extends StatelessWidget {
  const BuildIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.developer_mode_rounded, size: 18, color: AppColors.primaryBlue),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Developer Diagnostics (Debug Mode Only)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const ProfileDetailRow(label: 'Environment', value: 'Development Debug'),
          ProfileDetailRow(label: 'API Base URL', value: ApiConstants.baseUrl),
        ],
      ),
    );
  }
}

class ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              softWrap: true,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
