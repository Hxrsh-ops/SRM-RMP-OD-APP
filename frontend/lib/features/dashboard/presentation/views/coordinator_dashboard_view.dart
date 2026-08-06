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
  int _activeTab = 0; // 0 = Initial Approvals, 1 = Evidence Verification
  Map<String, int>? _analytics;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final repo = ref.read(workflowRepositoryProvider);
      final res = await repo.getCoordinatorAnalytics();
      if (mounted) {
        setState(() {
          _analytics = res;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCoordinatorApproveDialog(BuildContext context, OdRequest request) {
    final isEvidenceMode = request.status == OdStatus.pendingEvidenceCoordinator;
    final remarksController = TextEditingController(
      text: isEvidenceMode ? 'Completion evidence verified. Final OD granted.' : 'Approved for event participation. Awaiting post-event completion proof.',
    );
    final session = ref.read(authControllerProvider).session;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primaryBlue, size: 24),
            const SizedBox(width: AppSpacing.xs),
            Text(isEvidenceMode ? 'Final Evidence Verification' : 'Initial Department Approval'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.studentName} (${request.registerNumber})'),
            Text('Faculty Advisor: ${request.facultyAdvisorName} (Verified)'),
            if (isEvidenceMode && request.completionSummary != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Completion Report: "${request.completionSummary}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.md),
            const Text('Coordinator Decision Remarks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter decision notes...',
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
              final success = await ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                    requestId: request.id,
                    coordinatorId: session?.userId ?? '',
                    coordinatorName: session?.name ?? '',
                    approve: true,
                    comment: remarksController.text.trim(),
                  );
              await _fetchAnalytics();
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isEvidenceMode ? 'OD Request ${request.id} completed & granted!' : 'Request ${request.id} approved, awaiting evidence.')
                        : (errorMsg ?? 'Failed to approve request ${request.id}')),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
            child: Text(isEvidenceMode ? 'Complete & Grant OD' : 'Approve Request'),
          ),
        ],
      ),
    );
  }

  void _showCoordinatorRejectDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController();
    final session = ref.read(authControllerProvider).session;
    final isEvidenceMode = request.status == OdStatus.pendingEvidenceCoordinator;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            const SizedBox(width: AppSpacing.xs),
            Text(isEvidenceMode ? 'Request Evidence Revision' : 'Reject / Return Request'),
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
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isEvidenceMode ? 'Enter evidence revision requirements...' : 'Enter discrepancy explanation...',
                border: const OutlineInputBorder(),
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
                  const SnackBar(content: Text('Please specify a rejection/revision reason.'), backgroundColor: AppColors.danger),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              final success = await ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                    requestId: request.id,
                    coordinatorId: session?.userId ?? '',
                    coordinatorName: session?.name ?? '',
                    approve: false,
                    returnForCorrection: !isEvidenceMode,
                    comment: remarksController.text.trim(),
                  );
              await _fetchAnalytics();
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Request ${request.id} updated.' : (errorMsg ?? 'Failed to update request ${request.id}')),
                    backgroundColor: success ? AppColors.warning : AppColors.danger,
                  ),
                );
              }
            },
            child: Text(isEvidenceMode ? 'Request Revision' : 'Confirm Return'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allRequests = ref.watch(workflowControllerProvider.select((s) => s.requests));
    final isMobile = ResponsiveLayout.isMobile(context);

    final initialPending = allRequests.where((r) => r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved).toList();
    final evidencePending = allRequests.where((r) => r.status == OdStatus.pendingEvidenceCoordinator).toList();

    final activeList = (_activeTab == 0 ? initialPending : evidencePending).where((r) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return r.studentName.toLowerCase().contains(q) || r.registerNumber.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q);
    }).toList();

    final pendingCoordCount = initialPending.length;
    final awaitingEvidenceCount = _analytics?['approved_awaiting_evidence_count'] ?? allRequests.where((r) => r.status == OdStatus.approvedAwaitingEvidence).length;
    final pendingEvidenceCount = evidencePending.length;
    final completedCount = _analytics?['completed_count'] ?? allRequests.where((r) => r.status == OdStatus.completed).length;
    final totalCount = allRequests.length;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(workflowControllerProvider.notifier).loadAllData();
        await _fetchAnalytics();
      },
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
              'Department-wide On Duty approval queue & real-time analytics overview',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Department Real-Time Analytics Cards
            if (isMobile)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppMetricCard(
                          title: 'Pending Initial',
                          value: '$pendingCoordCount',
                          icon: Icons.hourglass_top_rounded,
                          statusType: AppStatusType.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppMetricCard(
                          title: 'Awaiting Proof',
                          value: '$awaitingEvidenceCount',
                          icon: Icons.pending_actions_rounded,
                          statusType: AppStatusType.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppMetricCard(
                          title: 'Pending Proof',
                          value: '$pendingEvidenceCount',
                          icon: Icons.fact_check_outlined,
                          statusType: AppStatusType.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppMetricCard(
                          title: 'Completed',
                          value: '$completedCount',
                          icon: Icons.verified_user_outlined,
                          statusType: AppStatusType.success,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AppMetricCard(
                      title: 'Pending Initial',
                      value: '$pendingCoordCount',
                      icon: Icons.hourglass_top_rounded,
                      statusType: AppStatusType.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Awaiting Proof',
                      value: '$awaitingEvidenceCount',
                      icon: Icons.pending_actions_rounded,
                      statusType: AppStatusType.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Pending Proof',
                      value: '$pendingEvidenceCount',
                      icon: Icons.fact_check_outlined,
                      statusType: AppStatusType.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Completed',
                      value: '$completedCount',
                      icon: Icons.verified_user_outlined,
                      statusType: AppStatusType.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Total Requests',
                      value: '$totalCount',
                      icon: Icons.analytics_outlined,
                      statusType: AppStatusType.info,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.lg),

            // Queue Choice Chips
            Row(
              children: [
                ChoiceChip(
                  label: Text('Initial Approvals ($pendingCoordCount)'),
                  selected: _activeTab == 0,
                  onSelected: (val) => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text('Evidence Verification ($pendingEvidenceCount)'),
                  selected: _activeTab == 1,
                  onSelected: (val) => setState(() => _activeTab = 1),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

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

            if (activeList.isEmpty)
              AppEmptyState(
                title: _activeTab == 0 ? 'No Pending Initial Approvals' : 'No Evidence Verification Queue',
                description: _activeTab == 0
                    ? 'All requests passed by Faculty Advisors have been processed.'
                    : 'No student completion proof documents are currently awaiting final coordinator sign-off.',
              )
            else
              Column(
                children: activeList.map((req) {
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Faculty Advisor: ${req.facultyAdvisorName} (Verified)',
                                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              AppStatusChip(label: req.status.displayName, statusType: req.status.statusType),
                            ],
                          ),
                          const AppDivider(),
                          if (isMobile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility_outlined, size: 16),
                                  label: const Text('Inspect Request'),
                                  onPressed: () => RequestDetailsModal.show(context, req),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                          icon: const Icon(Icons.close_rounded, size: 16),
                                          label: Text(_activeTab == 1 ? 'Revise' : 'Reject'),
                                          onPressed: () => _showCoordinatorRejectDialog(context, req),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                                          icon: const Icon(Icons.verified_rounded, size: 16),
                                          label: Text(_activeTab == 1 ? 'Grant OD' : 'Approve'),
                                          onPressed: () => _showCoordinatorApproveDialog(context, req),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
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
                                      label: Text(_activeTab == 1 ? 'Revise' : 'Reject'),
                                      onPressed: () => _showCoordinatorRejectDialog(context, req),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                                      icon: const Icon(Icons.verified_rounded, size: 16),
                                      label: Text(_activeTab == 1 ? 'Grant OD' : 'Approve'),
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
