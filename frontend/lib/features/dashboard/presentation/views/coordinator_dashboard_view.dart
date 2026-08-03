import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import '../../../od_workflow/domain/entities/od_request.dart';
import '../../../od_workflow/domain/entities/od_status.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';

class CoordinatorDashboardView extends ConsumerStatefulWidget {
  const CoordinatorDashboardView({super.key});

  @override
  ConsumerState<CoordinatorDashboardView> createState() => _CoordinatorDashboardViewState();
}

class _CoordinatorDashboardViewState extends ConsumerState<CoordinatorDashboardView> {
  final _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCoordinatorApproveDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController(text: 'Final Department Approval Granted.');
    final session = ref.read(authControllerProvider).session;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.primaryBlue, size: 24),
            SizedBox(width: AppSpacing.xs),
            Text('Final Department Approval'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.studentName} (${request.registerNumber})'),
            Text('Faculty Advisor: ${request.facultyAdvisorName} (Verified)'),
            const SizedBox(height: AppSpacing.md),
            const Text('Coordinator Decision Remarks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter final approval notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                    requestId: request.id,
                    coordinatorId: session?.userId ?? 'CO1001',
                    coordinatorName: session?.name ?? 'Prof. Ramesh Kumar',
                    approve: true,
                    comment: remarksController.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request ${request.id} granted final department approval.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Grant Final Approval'),
          ),
        ],
      ),
    );
  }

  void _showCoordinatorRejectDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController();
    final session = ref.read(authControllerProvider).session;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: AppSpacing.xs),
            Text('Reject / Return Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.studentName} (${request.registerNumber})'),
            const SizedBox(height: AppSpacing.md),
            const Text('Rejection / Return Remarks (Mandatory):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter discrepancy explanation...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () async {
              if (remarksController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Please specify a rejection reason.'), backgroundColor: AppColors.danger),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              await ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                    requestId: request.id,
                    coordinatorId: session?.userId ?? 'CO1001',
                    coordinatorName: session?.name ?? 'Prof. Ramesh Kumar',
                    approve: false,
                    comment: remarksController.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request ${request.id} rejected.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workflowState = ref.watch(workflowControllerProvider);
    final allRequests = workflowState.requests;
    final pendingRequests = allRequests.where((r) {
      final matchesStatus = r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved;
      if (_filterQuery.isEmpty) return matchesStatus;
      final q = _filterQuery.toLowerCase();
      return matchesStatus && (r.studentName.toLowerCase().contains(q) || r.registerNumber.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q));
    }).toList();

    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordinator Approval Workspace',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Department-wide On Duty approval queue & analytics overview',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Department Analytics Cards
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: AppMetricCard(
                      title: 'Pending Coordinator',
                      value: '${pendingRequests.length}',
                      icon: Icons.hourglass_top_rounded,
                      statusType: AppStatusType.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Total Department Completed',
                      value: '${allRequests.where((r) => r.status == OdStatus.completed).length}',
                      icon: Icons.verified_user_outlined,
                      statusType: AppStatusType.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Total Submissions',
                      value: '${allRequests.length}',
                      icon: Icons.analytics_outlined,
                      statusType: AppStatusType.info,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  AppMetricCard(
                    title: 'Pending Coordinator',
                    value: '${pendingRequests.length}',
                    icon: Icons.hourglass_top_rounded,
                    statusType: AppStatusType.warning,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppMetricCard(
                          title: 'Completed',
                          value: '${allRequests.where((r) => r.status == OdStatus.completed).length}',
                          icon: Icons.verified_user_outlined,
                          statusType: AppStatusType.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppMetricCard(
                          title: 'Total',
                          value: '${allRequests.length}',
                          icon: Icons.analytics_outlined,
                          statusType: AppStatusType.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.lg),

            // Search Bar
            SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filterQuery = val.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search department requests...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: AppSpacing.md),
                  border: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (pendingRequests.isEmpty)
              const AppEmptyState(
                title: 'No Pending Coordinator Approvals',
                description: 'All requests passed by Faculty Advisors have been approved.',
              )
            else
              Column(
                children: pendingRequests.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
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
                                      '${req.studentName} (${req.registerNumber})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Faculty Advisor: ${req.facultyAdvisorName} (Approved)',
                                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              AppStatusChip(label: req.status.displayName, statusType: req.status.statusType),
                            ],
                          ),
                          const AppDivider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                label: const Text('Inspect Request'),
                                onPressed: () => RequestDetailsModal.show(context, req),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    label: const Text('Reject'),
                                    onPressed: () => _showCoordinatorRejectDialog(context, req),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.verified_rounded, size: 16),
                                    label: const Text('Grant Approval'),
                                    onPressed: () => _showCoordinatorApproveDialog(context, req),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
