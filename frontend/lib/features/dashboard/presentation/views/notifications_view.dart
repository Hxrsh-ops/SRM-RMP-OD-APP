import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workflowState = ref.watch(workflowControllerProvider);
    final notifications = workflowState.notifications;
    final requests = workflowState.requests;
    final isMobile = ResponsiveLayout.isMobile(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Updates regarding your On Duty applications and advisor approvals',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (notifications.any((n) => !n.isRead)) ...[
                  const SizedBox(width: AppSpacing.sm),
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded, color: AppColors.primaryBlue),
                      onPressed: () => ref.read(workflowControllerProvider.notifier).markNotificationsRead(),
                      tooltip: 'Mark All Read',
                    )
                  else
                    TextButton.icon(
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Mark All Read'),
                      onPressed: () => ref.read(workflowControllerProvider.notifier).markNotificationsRead(),
                    ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (notifications.isEmpty)
              const AppEmptyState(
                title: 'No Notifications',
                description: 'You are all caught up! System notifications will appear here.',
              )
            else
              Column(
                children: notifications.map((n) {
                  final req = n.requestId != null
                      ? requests.where((r) => r.id == n.requestId).firstOrNull
                      : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppClickableCard(
                      onTap: req != null ? () => RequestDetailsModal.show(context, req) : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                            color: n.isRead ? AppColors.textSecondary : AppColors.primaryBlue,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  n.message,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.timestamp.toString().split('.')[0],
                                  style: const TextStyle(fontSize: 10, color: AppColors.textDisabled),
                                ),
                              ],
                            ),
                          ),
                          if (req != null)
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
