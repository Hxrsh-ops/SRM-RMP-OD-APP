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
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isEvidenceMode ? 'Verify Completion Evidence' : 'Faculty Advisor Approval',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref.read(workflowControllerProvider.notifier).processFacultyAction(
                    requestId: request.id,
                    facultyId: session?.userId ?? '',
                    facultyName: session?.name ?? '',
                    approve: true,
                    comment: remarksController.text.trim(),
                  );
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                if (success) {
                  AppSnackbar.showSuccess(
                    context,
                    isEvidenceMode ? 'Completion evidence verified & passed to coordinator.' : 'Faculty approval submitted successfully for ${request.id}.',
                  );
                } else {
                  AppSnackbar.showError(
                    context,
                    errorMsg ?? 'Failed to process faculty action.',
                  );
                }
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
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isEvidenceMode ? 'Request Evidence Revision' : 'Reject OD Request',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            onPressed: () async {
              if (remarksController.text.trim().isEmpty) {
                AppSnackbar.showError(dialogCtx, 'Please specify a rejection/revision reason.');
                return;
              }
              Navigator.pop(dialogCtx);
              final success = await ref.read(workflowControllerProvider.notifier).processFacultyAction(
                    requestId: request.id,
                    facultyId: session?.userId ?? '',
                    facultyName: session?.name ?? '',
                    approve: false,
                    comment: remarksController.text.trim(),
                  );
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                if (success) {
                  AppSnackbar.showWarning(context, 'Request ${request.id} updated.');
                } else {
                  AppSnackbar.showError(context, errorMsg ?? 'Failed to process faculty action.');
                }
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
    final allRequests = ref.watch(workflowControllerProvider.select((s) => s.requests));
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
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text('Initial Approvals (${initialPending.length})'),
                  selected: _activeTab == 0,
                  onSelected: (val) => setState(() => _activeTab = 0),
                ),
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
                          // Header Row: Student Name, Register Number, Status Chip
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
                                      req.registerNumber,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              AppStatusChip(label: req.status.displayName, statusType: req.status.statusType),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Event Name & Duration Badge Container
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 18, color: AppColors.primaryBlue),
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
                                        'Duration: ${req.durationDays} ${req.durationDays == 1 ? "Day" : "Days"} (${req.startDate.toString().split(" ")[0]})',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AppDivider(),

                          // Uniform Equal Height & Width Action Buttons
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
                                          onPressed: () => _showFacultyRejectDialog(context, req),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          ),
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
                                      onPressed: () => _showFacultyRejectDialog(context, req),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                      ),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: Text(_activeTab == 1 ? 'Verify' : 'Approve'),
                                      onPressed: () => _showFacultyApproveDialog(context, req),
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
