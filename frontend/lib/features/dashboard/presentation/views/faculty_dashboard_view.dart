import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import '../../../od_workflow/domain/entities/od_request.dart';
import '../../../od_workflow/domain/entities/od_status.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';

class FacultyDashboardView extends ConsumerStatefulWidget {
  const FacultyDashboardView({super.key});

  @override
  ConsumerState<FacultyDashboardView> createState() => _FacultyDashboardViewState();
}

class _FacultyDashboardViewState extends ConsumerState<FacultyDashboardView> {
  final _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFacultyApproveDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController(text: 'Verified student academic eligibility & event details.');
    final session = ref.read(authControllerProvider).session;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
            SizedBox(width: AppSpacing.xs),
            Text('Approve OD Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.studentName} (${request.registerNumber})'),
            Text('Event: ${request.reason} (${request.durationDays} Days)'),
            const SizedBox(height: AppSpacing.md),
            const Text('Advisor Approval Remarks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter recommendation notes for Coordinator...',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(workflowControllerProvider.notifier).processFacultyAction(
                    requestId: request.id,
                    facultyId: session?.userId ?? 'FA1001',
                    facultyName: session?.name ?? 'Dr. Karthik B',
                    approve: true,
                    comment: remarksController.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request ${request.id} approved and forwarded to Coordinator.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _showFacultyRejectDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController();
    final session = ref.read(authControllerProvider).session;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.danger, size: 24),
            SizedBox(width: AppSpacing.xs),
            Text('Reject OD Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.studentName} (${request.registerNumber})'),
            const SizedBox(height: AppSpacing.md),
            const Text('Reason for Rejection (Mandatory):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Explain rejection criteria (e.g. Low attendance %)...',
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
              await ref.read(workflowControllerProvider.notifier).processFacultyAction(
                    requestId: request.id,
                    facultyId: session?.userId ?? 'FA1001',
                    facultyName: session?.name ?? 'Dr. Karthik B',
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
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workflowState = ref.watch(workflowControllerProvider);
    final pendingRequests = workflowState.requests.where((r) {
      final matchesStatus = r.status == OdStatus.pendingFaculty || r.status == OdStatus.submitted;
      if (_filterQuery.isEmpty) return matchesStatus;
      final q = _filterQuery.toLowerCase();
      return matchesStatus && (r.studentName.toLowerCase().contains(q) || r.registerNumber.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q));
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faculty Advisor Workspace',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Review student attendance eligibility and approve On Duty submissions',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppMetricCard(
              title: 'Pending Faculty Reviews',
              value: '${pendingRequests.length}',
              icon: Icons.assignment_late_outlined,
              statusType: AppStatusType.warning,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Search Bar
            SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filterQuery = val.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search by student name, register number, event...',
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
                title: 'No Pending Reviews',
                description: 'All student OD requests assigned to your advisor queue have been reviewed.',
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
                                      'Event: ${req.reason} • ${req.durationDays} Days',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                                label: const Text('View Full Details'),
                                onPressed: () => RequestDetailsModal.show(context, req),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    label: const Text('Reject'),
                                    onPressed: () => _showFacultyRejectDialog(context, req),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Approve'),
                                    onPressed: () => _showFacultyApproveDialog(context, req),
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
