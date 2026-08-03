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

class FacultyDashboardView extends ConsumerStatefulWidget {
  const FacultyDashboardView({super.key});

  @override
  ConsumerState<FacultyDashboardView> createState() => _FacultyDashboardViewState();
}

class _FacultyDashboardViewState extends ConsumerState<FacultyDashboardView> {
  final _searchController = TextEditingController();
  String _filterQuery = '';
  int _activeTab = 0; // 0 = Initial Approvals, 1 = Evidence Verification

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFacultyApproveDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController(text: 'Approved by Faculty Advisor.');
    final session = ref.read(authControllerProvider).session;
    final isEvidenceMode = request.status == OdStatus.pendingEvidenceFaculty;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
            const SizedBox(width: AppSpacing.xs),
            Text(isEvidenceMode ? 'Verify Completion Evidence' : 'Faculty Advisor Approval'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.studentName} (${request.registerNumber})'),
            Text('Event: ${request.reason} • ${request.durationDays} Days'),
            if (isEvidenceMode && request.completionSummary != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Report: "${request.completionSummary}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.md),
            const Text('Advisor Recommendation Remarks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter recommendation notes...',
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
                    content: Text(isEvidenceMode ? 'Evidence verified & passed to coordinator.' : 'Request ${request.id} approved.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(isEvidenceMode ? 'Verify Evidence' : 'Approve & Forward'),
          ),
        ],
      ),
    );
  }

  void _showFacultyRejectDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController();
    final session = ref.read(authControllerProvider).session;
    final isEvidenceMode = request.status == OdStatus.pendingEvidenceFaculty;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 24),
            const SizedBox(width: AppSpacing.xs),
            Text(isEvidenceMode ? 'Request Evidence Revision' : 'Reject OD Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.studentName} (${request.registerNumber})'),
            const SizedBox(height: AppSpacing.md),
            const Text('Reason Remarks (Mandatory):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isEvidenceMode ? 'Explain evidence revision requirements...' : 'Enter rejection reason...',
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
                  const SnackBar(content: Text('Please specify a valid explanation reason.'), backgroundColor: AppColors.danger),
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
                    content: Text(isEvidenceMode ? 'Evidence revision requested.' : 'Request ${request.id} rejected.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: Text(isEvidenceMode ? 'Request Revision' : 'Confirm Rejection'),
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
    final isMobile = ResponsiveLayout.isMobile(context);

    final initialPending = allRequests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.submitted).toList();
    final evidencePending = allRequests.where((r) => r.status == OdStatus.pendingEvidenceFaculty).toList();

    final activeList = (_activeTab == 0 ? initialPending : evidencePending).where((r) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return r.studentName.toLowerCase().contains(q) || r.registerNumber.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q);
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

            Row(
              children: [
                Expanded(
                  child: AppMetricCard(
                    title: 'Pending Initial Reviews',
                    value: '${initialPending.length}',
                    icon: Icons.assignment_late_outlined,
                    statusType: AppStatusType.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppMetricCard(
                    title: 'Pending Evidence Reviews',
                    value: '${evidencePending.length}',
                    icon: Icons.fact_check_outlined,
                    statusType: AppStatusType.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tab Filter Buttons
            Row(
              children: [
                ChoiceChip(
                  label: Text('Initial Approvals (${initialPending.length})'),
                  selected: _activeTab == 0,
                  onSelected: (val) => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text('Evidence Verification (${evidencePending.length})'),
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

            if (activeList.isEmpty)
              AppEmptyState(
                title: _activeTab == 0 ? 'No Pending Initial Reviews' : 'No Evidence Pending Verification',
                description: _activeTab == 0
                    ? 'All student OD requests assigned to your advisor queue have been reviewed.'
                    : 'No student completion proof documents are currently awaiting your verification.',
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
                                      'Event: ${req.reason} • ${req.durationDays} Days',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                                  label: const Text('View Full Details'),
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
                                          onPressed: () => _showFacultyRejectDialog(context, req),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                          icon: const Icon(Icons.check_rounded, size: 16),
                                          label: Text(_activeTab == 1 ? 'Verify' : 'Approve'),
                                          onPressed: () => _showFacultyApproveDialog(context, req),
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
                                  label: const Text('View Full Details'),
                                  onPressed: () => RequestDetailsModal.show(context, req),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      label: Text(_activeTab == 1 ? 'Revise' : 'Reject'),
                                      onPressed: () => _showFacultyRejectDialog(context, req),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: Text(_activeTab == 1 ? 'Verify' : 'Approve'),
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
