import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = ref.watch(workflowControllerProvider.select((s) => s.notifications));
    final requests = ref.watch(workflowControllerProvider.select((s) => s.requests));
    final isMobile = ResponsiveLayout.isMobile(context);

    final allSelected = notifications.isNotEmpty && _selectedIds.length == notifications.length;

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
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
                      'Updates regarding your On Duty applications and approvals',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (notifications.any((n) => !n.isRead))
                      OutlinedButton.icon(
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Mark Read'),
                        onPressed: () => ref.read(workflowControllerProvider.notifier).markNotificationsRead(),
                      ),
                    if (notifications.isNotEmpty) ...[
                      OutlinedButton.icon(
                        icon: Icon(allSelected ? Icons.deselect : Icons.select_all, size: 16),
                        label: Text(allSelected ? 'Deselect All' : 'Select All'),
                        onPressed: () {
                          setState(() {
                            if (allSelected) {
                              _selectedIds.clear();
                            } else {
                              _selectedIds.addAll(notifications.map((n) => n.id));
                            }
                          });
                        },
                      ),
                      if (_selectedIds.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: Text('Delete (${_selectedIds.length})'),
                          onPressed: () => _deleteSelected(context),
                        ),
                      if (_selectedIds.isEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                          label: const Text('Clear All'),
                          onPressed: () => _confirmClearAll(context),
                        ),
                    ],
                  ],
                ),
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
                  final isSelected = _selectedIds.contains(n.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryBlue : Colors.black12,
                          width: isSelected ? 1.5 : 0.8,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (_selectedIds.isNotEmpty) {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(n.id);
                              } else {
                                _selectedIds.add(n.id);
                              }
                            });
                          } else if (req != null) {
                            RequestDetailsModal.show(context, req);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.add(n.id);
                                    } else {
                                      _selectedIds.remove(n.id);
                                    }
                                  });
                                },
                              ),
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
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                tooltip: 'Delete notification',
                                onPressed: () async {
                                  await ref.read(workflowControllerProvider.notifier).deleteNotification(n.id);
                                  setState(() => _selectedIds.remove(n.id));
                                },
                              ),
                              if (req != null)
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                        ),
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

  void _deleteSelected(BuildContext context) async {
    final count = _selectedIds.length;
    final idsToDelete = _selectedIds.toList();
    final success = await ref.read(workflowControllerProvider.notifier).deleteNotificationsBulk(ids: idsToDelete);
    if (mounted) {
      if (success) {
        setState(() => _selectedIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $count notification(s)')));
      }
    }
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(workflowControllerProvider.notifier).deleteNotificationsBulk();
              setState(() => _selectedIds.clear());
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
