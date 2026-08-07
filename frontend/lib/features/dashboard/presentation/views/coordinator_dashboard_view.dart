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
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                if (success) {
                  AppSnackbar.showSuccess(
                    context,
                    isEvidenceMode ? 'OD Request ${request.id} completed & granted!' : 'Request ${request.id} approved by coordinator.',
                  );
                } else {
                  AppSnackbar.showError(
                    context,
                    errorMsg ?? 'Failed to approve request ${request.id}.',
                  );
                }
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
                AppSnackbar.showError(dialogCtx, 'Please specify a rejection/revision reason.');
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
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                if (success) {
                  AppSnackbar.showWarning(context, 'Request ${request.id} updated.');
                } else {
                  AppSnackbar.showError(context, errorMsg ?? 'Failed to update request ${request.id}');
                }
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
    final analytics = ref.watch(workflowControllerProvider.select((s) => s.analytics));
    final isMobile = ResponsiveLayout.isMobile(context);

    final initialPending = allRequests.where((r) => r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved).toList();
    final evidencePending = allRequests.where((r) => r.status == OdStatus.pendingEvidenceCoordinator).toList();

    final activeList = (_activeTab == 0 ? initialPending : evidencePending).where((r) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return r.studentName.toLowerCase().contains(q) || r.registerNumber.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q);
    }).toList();

    final pendingCoordCount = analytics?['pending_coordinator_count'] ?? initialPending.length;
    final awaitingEvidenceCount = analytics?['approved_awaiting_evidence_count'] ?? allRequests.where((r) => r.status == OdStatus.approvedAwaitingEvidence).length;
    final pendingEvidenceCount = analytics?['pending_evidence_coordinator_count'] ?? evidencePending.length;
    final completedCount = analytics?['completed_count'] ?? allRequests.where((r) => r.status == OdStatus.completed).length;
    final totalCount = analytics?['total_submissions_count'] ?? allRequests.length;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(workflowControllerProvider.notifier).loadAllData();
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primaryContainer,
                                child: Text(
                                  req.studentName.isNotEmpty ? req.studentName[0].toUpperCase() : 'S',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req.studentName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${req.registerNumber} • Advisor: ${req.facultyAdvisorName}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                          const SizedBox(height: AppSpacing.md),

                          // Event Details Box
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primaryBlue),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req.reason,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${req.durationDays} Days (${req.startDate.toString().split(" ")[0]}) • Venue: ${req.venue}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AppDivider(),

                          // Equal Height & Width Responsive Action Buttons
                          if (isMobile)
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryBlue,
                                      side: const BorderSide(color: AppColors.primaryBlue),
                                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                    ),
                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                    label: const Text('View Details'),
                                    onPressed: () => RequestDetailsModal.show(context, req),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.danger,
                                            side: const BorderSide(color: AppColors.danger),
                                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          ),
                                          icon: const Icon(Icons.close_rounded, size: 16),
                                          label: Text(_activeTab == 1 ? 'Revise' : 'Reject'),
                                          onPressed: () => _showCoordinatorRejectDialog(context, req),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryBlue,
                                            foregroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          ),
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
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlue,
                                        side: const BorderSide(color: AppColors.primaryBlue),
                                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                      ),
                                      icon: const Icon(Icons.visibility_outlined, size: 16),
                                      label: const Text('View Details'),
                                      onPressed: () => RequestDetailsModal.show(context, req),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(color: AppColors.danger),
                                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                      ),
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      label: Text(_activeTab == 1 ? 'Revise' : 'Reject'),
                                      onPressed: () => _showCoordinatorRejectDialog(context, req),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                      ),
                                      icon: const Icon(Icons.verified_rounded, size: 16),
                                      label: Text(_activeTab == 1 ? 'Grant OD' : 'Approve'),
                                      onPressed: () => _showCoordinatorApproveDialog(context, req),
                                    ),
                                  ),
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
