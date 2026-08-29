import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../admin/presentation/controllers/admin_controller.dart';
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
  final Set<String> _selectedRequestIds = {};
  bool _isBatchProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _processBatchApproval(List<OdRequest> requests) async {
    final session = ref.read(authControllerProvider).session;
    final selectedReqs = requests.where((r) => _selectedRequestIds.contains(r.id)).toList();
    if (selectedReqs.isEmpty) return;

    final isEvidence = _activeTab == 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batch Approve ${selectedReqs.length} Requests?'),
        content: Text('Are you sure you want to approve all ${selectedReqs.length} selected On Duty requests concurrently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Approve (${selectedReqs.length})'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBatchProcessing = true);
    int successCount = 0;
    for (final req in selectedReqs) {
      final success = await ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
            requestId: req.id,
            coordinatorId: session?.userId ?? '',
            coordinatorName: session?.name ?? '',
            approve: true,
            comment: isEvidence ? 'Batch verified completion evidence.' : 'Batch approved via Queue Selection.',
          );
      if (success) successCount++;
    }

    setState(() {
      _selectedRequestIds.clear();
      _isBatchProcessing = false;
    });

    if (mounted) {
      AppSnackbar.showSuccess(context, 'Successfully batch approved $successCount requests.');
    }
  }

  void _showCoordinatorApproveDialog(BuildContext context, OdRequest request) {
    final isEvidenceMode = request.status == OdStatus.pendingEvidenceCoordinator;
    final remarksController = TextEditingController(
      text: isEvidenceMode ? 'Completion evidence verified. Final OD granted.' : 'Approved for event participation. Awaiting post-event completion proof.',
    );
    final session = ref.read(authControllerProvider).session;
    final role = session?.role ?? 'COORDINATOR';
    final roleName = role == 'HOD' ? 'Head of Department' : (role == 'DEAN' ? 'Executive Dean' : 'Coordinator');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isEvidenceMode ? 'Final Evidence Verification' : '$roleName Approval',
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
            Text('Faculty Advisor: ${request.facultyAdvisorName} (Verified)'),
            if (isEvidenceMode && request.completionSummary != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Completion Report: "${request.completionSummary}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('$roleName Decision Remarks:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
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
                    isEvidenceMode ? 'OD Request ${request.id} completed & granted!' : 'Request ${request.id} approved by $roleName.',
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
    final isEvidenceMode = request.status == OdStatus.pendingEvidenceCoordinator;
    final session = ref.read(authControllerProvider).session;

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
            Text(
              isEvidenceMode ? 'Evidence Revision Requirements (Mandatory):' : 'Rejection Reason Remarks (Mandatory):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isEvidenceMode ? 'Enter evidence revision requirements...' : 'Enter rejection reason explanation...',
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
                AppSnackbar.showError(dialogCtx, 'Please specify a rejection reason.');
                return;
              }
              Navigator.pop(dialogCtx);
              final success = await ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                    requestId: request.id,
                    coordinatorId: session?.userId ?? '',
                    coordinatorName: session?.name ?? '',
                    approve: false,
                    returnForCorrection: false,
                    comment: remarksController.text.trim(),
                  );
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                if (success) {
                  AppSnackbar.showWarning(context, 'Request ${request.id} rejected.');
                } else {
                  AppSnackbar.showError(context, errorMsg ?? 'Failed to reject request ${request.id}');
                }
              }
            },
            child: Text(isEvidenceMode ? 'Request Revision' : 'Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _showCoordinatorEscalateDialog(BuildContext context, OdRequest request) {
    final remarksController = TextEditingController();
    final session = ref.read(authControllerProvider).session;
    final role = session?.role ?? 'COORDINATOR';
    final isHod = role == 'HOD';
    final targetRole = isHod ? 'DEAN' : 'HOD';
    final targetTitle = isHod ? 'Escalate to Executive Dean' : 'Escalate to Head of Department';
    final targetSubtitle = isHod
        ? 'Request will be escalated to the Executive Dean for campus-wide administrative review and final clearance.'
        : 'Request will be escalated to the Head of Department for departmental concurrence.';
    final inputLabel = isHod
        ? 'Escalation Reason / Notes for Executive Dean (Mandatory):'
        : 'Escalation Reason / Notes for HOD (Mandatory):';
    final btnLabel = isHod ? 'Escalate to Dean' : 'Escalate to HOD';
    final hintText = isHod ? 'Enter reason for Executive Dean review...' : 'Enter reason for HOD concurrence/review...';
    final successMsg = isHod
        ? 'Request ${request.id} escalated to Executive Dean successfully.'
        : 'Request ${request.id} escalated to HOD successfully.';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            const Icon(Icons.forward_to_inbox, color: Color(0xFF1A365D), size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                targetTitle,
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
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A365D).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF1A365D)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      targetSubtitle,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF1A365D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(inputLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: hintText,
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A365D),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(btnLabel),
            onPressed: () async {
              if (remarksController.text.trim().isEmpty) {
                AppSnackbar.showError(dialogCtx, 'Please specify why this request is being escalated.');
                return;
              }
              Navigator.pop(dialogCtx);
              final success = await ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                    requestId: request.id,
                    coordinatorId: session?.userId ?? '',
                    coordinatorName: session?.name ?? '',
                    approve: true,
                    escalateTo: targetRole,
                    comment: '[Escalated to $targetRole]: ${remarksController.text.trim()}',
                  );
              if (context.mounted) {
                final errorMsg = ref.read(workflowControllerProvider).errorMessage;
                if (success) {
                  AppSnackbar.showSuccess(
                    context,
                    successMsg,
                  );
                } else {
                  AppSnackbar.showError(
                    context,
                    errorMsg ?? 'Failed to escalate request.',
                  );
                }
              }
            },
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
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final role = session?.role ?? 'COORDINATOR';
    final isHod = role == 'HOD';
    final isDean = role == 'DEAN';

    final orgSettings = ref.watch(adminSettingsProvider).valueOrNull;
    final workflowMode = orgSettings?.workflowMode ?? 'STANDARD';
    final evidenceMode = orgSettings?.evidenceWorkflowMode ?? 'FA_ONLY';

    final initialPending = allRequests.where((r) {
      final isInitial = r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved;
      if (!isInitial) return false;
      if (isDean) {
        return r.isEscalatedToDean;
      }
      if (isHod) {
        if (r.isEscalatedToDean) return false;
        return r.isEscalatedToHod || r.isDirectHodSubmission || workflowMode == 'DIRECT_HOD';
      }
      // Coordinator
      if (r.isEscalatedToHod || r.isEscalatedToDean) return false;
      if (r.isDirectHodSubmission || workflowMode == 'DIRECT_HOD') return false;
      return true;
    }).toList();

    final evidencePending = allRequests.where((r) {
      if (r.status != OdStatus.pendingEvidenceCoordinator) return false;
      if (isDean) {
        return r.isEscalatedToDean;
      }
      if (isHod) {
        if (r.isEscalatedToDean) return false;
        return r.isEscalatedToHod || evidenceMode == 'FA_HOD';
      }
      // Coordinator
      if (r.isEscalatedToHod || r.isEscalatedToDean) return false;
      if (evidenceMode == 'FA_ONLY' || evidenceMode == 'FA_HOD') return false;
      return true;
    }).toList();

    final awaitingEvidenceList = allRequests.where((r) {
      if (r.status != OdStatus.approvedAwaitingEvidence) return false;
      if (isDean) return r.isEscalatedToDean;
      if (isHod) {
        if (r.isEscalatedToDean) return false;
        return r.isEscalatedToHod || r.isDirectHodSubmission || workflowMode == 'DIRECT_HOD' || evidenceMode == 'FA_HOD';
      }
      // Coordinator
      if (r.isEscalatedToHod || r.isEscalatedToDean) return false;
      if (r.isDirectHodSubmission || workflowMode == 'DIRECT_HOD' || evidenceMode == 'FA_HOD') return false;
      return true;
    }).toList();
    final completedList = allRequests.where((r) => r.status == OdStatus.completed).toList();

    final pendingCoordCount = initialPending.length;
    final awaitingEvidenceCount = awaitingEvidenceList.length;
    final pendingEvidenceCount = evidencePending.length;
    final completedCount = completedList.length;
    final totalCount = allRequests.length;

    List<OdRequest> baseList;
    switch (_activeTab) {
      case 0:
        baseList = initialPending;
        break;
      case 1:
        baseList = evidencePending;
        break;
      case 2:
        baseList = awaitingEvidenceList;
        break;
      case 3:
        baseList = completedList;
        break;
      case 4:
      default:
        baseList = allRequests;
        break;
    }

    final activeList = baseList.where((r) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return r.studentName.toLowerCase().contains(q) || r.registerNumber.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q);
    }).toList();

    final workspaceTitle = isDean
        ? 'Executive Dean Clearance Workspace'
        : (isHod ? 'Head of Department (HOD) Approval Workspace' : 'Coordinator Approval Workspace');
    final workspaceSubtitle = isDean
        ? 'Campus-wide escalated On Duty clearance queue & analytics overview'
        : (isHod
            ? 'Department-wide Head of Department approval queue & analytics overview'
            : 'Department-wide On Duty approval queue & real-time analytics overview');

    Widget buildMetricTabCard({
      required String title,
      required String count,
      required IconData icon,
      required Color color,
      required int tabIndex,
    }) {
      final isSelected = _activeTab == tabIndex;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeTab = tabIndex;
              _selectedRequestIds.clear();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? color.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : const Color(0xFF1A365D),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? color : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspaceTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        workspaceSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Export CSV'),
                  onPressed: () async {
                    try {
                      final repo = ref.read(workflowRepositoryProvider);
                      final csvStr = await repo.exportDepartmentOdCsv();
                      FileDownloadHelper.downloadCsv(
                        csvContent: csvStr,
                        filename: 'department_od_report_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Department OD Report downloaded successfully.'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Department Real-Time Interactive Analytics Tabs
            if (isMobile)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildMetricTabCard(
                          title: 'Pending Initial',
                          count: '$pendingCoordCount',
                          icon: Icons.hourglass_top_rounded,
                          color: Colors.amber.shade800,
                          tabIndex: 0,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: buildMetricTabCard(
                          title: 'Pending Proof',
                          count: '$pendingEvidenceCount',
                          icon: Icons.fact_check_outlined,
                          color: Colors.orange.shade800,
                          tabIndex: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: buildMetricTabCard(
                          title: 'Awaiting Proof',
                          count: '$awaitingEvidenceCount',
                          icon: Icons.pending_actions_rounded,
                          color: Colors.blue.shade700,
                          tabIndex: 2,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: buildMetricTabCard(
                          title: 'Completed',
                          count: '$completedCount',
                          icon: Icons.verified_user_outlined,
                          color: Colors.green.shade700,
                          tabIndex: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  buildMetricTabCard(
                    title: 'All Department Requests',
                    count: '$totalCount',
                    icon: Icons.analytics_outlined,
                    color: const Color(0xFF1A365D),
                    tabIndex: 4,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: buildMetricTabCard(
                      title: 'Pending Initial',
                      count: '$pendingCoordCount',
                      icon: Icons.hourglass_top_rounded,
                      color: Colors.amber.shade800,
                      tabIndex: 0,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: buildMetricTabCard(
                      title: 'Pending Proof',
                      count: '$pendingEvidenceCount',
                      icon: Icons.fact_check_outlined,
                      color: Colors.orange.shade800,
                      tabIndex: 1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: buildMetricTabCard(
                      title: 'Awaiting Proof',
                      count: '$awaitingEvidenceCount',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.blue.shade700,
                      tabIndex: 2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: buildMetricTabCard(
                      title: 'Completed',
                      count: '$completedCount',
                      icon: Icons.verified_user_outlined,
                      color: Colors.green.shade700,
                      tabIndex: 3,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: buildMetricTabCard(
                      title: 'All Requests',
                      count: '$totalCount',
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF1A365D),
                      tabIndex: 4,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.md),

            // Search Bar & Select All Bar
            Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                ),
                if (activeList.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: Icon(
                      _selectedRequestIds.length == activeList.length && activeList.isNotEmpty
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    label: Text(_selectedRequestIds.length == activeList.length ? 'Deselect All' : 'Select All'),
                    onPressed: () {
                      setState(() {
                        if (_selectedRequestIds.length == activeList.length) {
                          _selectedRequestIds.clear();
                        } else {
                          _selectedRequestIds.addAll(activeList.map((r) => r.id));
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Batch Action Floating Toolbar
            if (_selectedRequestIds.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A365D),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checklist_rtl_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedRequestIds.length} Selected',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.white70, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => setState(() => _selectedRequestIds.clear()),
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                          ),
                          icon: _isBatchProcessing
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.done_all_rounded, size: 15),
                          label: Text(_isBatchProcessing ? 'Processing...' : 'Approve (${_selectedRequestIds.length})', style: const TextStyle(fontSize: 12)),
                          onPressed: _isBatchProcessing ? null : () => _processBatchApproval(activeList),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (activeList.isEmpty)
              () {
                String emptyTitle;
                String emptyDesc;
                switch (_activeTab) {
                  case 0:
                    emptyTitle = 'No Pending Approvals';
                    emptyDesc = 'All department On Duty initial requests have been processed.';
                    break;
                  case 1:
                    emptyTitle = 'No Pending Evidence Reviews';
                    emptyDesc = 'No event completion evidence is waiting for verification.';
                    break;
                  case 2:
                    emptyTitle = 'No ODs Awaiting Proof';
                    emptyDesc = 'No approved requests are currently waiting for student proof submission.';
                    break;
                  case 3:
                    emptyTitle = 'No Completed ODs';
                    emptyDesc = 'No department On Duty requests have been finalized yet.';
                    break;
                  case 4:
                  default:
                    emptyTitle = 'No Department Requests';
                    emptyDesc = 'No On Duty requests found in this department.';
                    break;
                }
                return AppEmptyState(
                  title: emptyTitle,
                  description: _filterQuery.isEmpty ? emptyDesc : 'No requests matched "$_filterQuery".',
                );
              }()
            else
              Column(
                children: activeList.map((req) {
                  final isSelected = _selectedRequestIds.contains(req.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF1A365D),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedRequestIds.add(req.id);
                                    } else {
                                      _selectedRequestIds.remove(req.id);
                                    }
                                  });
                                },
                              ),
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
                              AppStatusChip(label: req.statusDisplayLabel, statusType: req.status.statusType),
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
                          const SizedBox(height: AppSpacing.md),

                          // Responsive Action Buttons per Status
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isInitialPending = req.status == OdStatus.pendingCoordinator || req.status == OdStatus.facultyApproved;
                              final isEvidencePending = req.status == OdStatus.pendingEvidenceCoordinator;

                              if (isEvidencePending) {
                                if (constraints.maxWidth < 600) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primaryBlue,
                                            side: const BorderSide(color: AppColors.primaryBlue),
                                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          ),
                                          icon: const Icon(Icons.visibility_outlined, size: 16),
                                          label: const Text('View Evidence', style: TextStyle(fontSize: 12.5)),
                                          onPressed: () => RequestDetailsModal.show(context, req),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 42,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.danger,
                                                  side: const BorderSide(color: AppColors.danger),
                                                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                                ),
                                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                                label: const Text('Revision', style: TextStyle(fontSize: 12.5)),
                                                onPressed: () => _showCoordinatorRejectDialog(context, req),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SizedBox(
                                              height: 42,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryBlue,
                                                  foregroundColor: Colors.white,
                                                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                                ),
                                                icon: const Icon(Icons.verified_rounded, size: 16),
                                                label: const Text('Grant Final OD', style: TextStyle(fontSize: 12.5)),
                                                onPressed: () => _showCoordinatorApproveDialog(context, req),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primaryBlue,
                                          side: const BorderSide(color: AppColors.primaryBlue),
                                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.visibility_outlined, size: 15),
                                        label: const Text('View Evidence', style: TextStyle(fontSize: 12)),
                                        onPressed: () => RequestDetailsModal.show(context, req),
                                      ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: const BorderSide(color: AppColors.danger),
                                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.refresh_rounded, size: 15),
                                        label: const Text('Revision', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _showCoordinatorRejectDialog(context, req),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.verified_rounded, size: 15),
                                        label: const Text('Grant Final OD', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _showCoordinatorApproveDialog(context, req),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (isInitialPending) {
                                final canEscalate = (role == 'COORDINATOR' && !req.isEscalatedToHod && !req.isEscalatedToDean) ||
                                    (role == 'HOD' && !req.isEscalatedToDean);

                                if (constraints.maxWidth < 600) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 42,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.primaryBlue,
                                                  side: const BorderSide(color: AppColors.primaryBlue),
                                                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                                ),
                                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                                label: const Text('Details', style: TextStyle(fontSize: 12.5)),
                                                onPressed: () => RequestDetailsModal.show(context, req),
                                              ),
                                            ),
                                          ),
                                          if (canEscalate) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SizedBox(
                                                height: 42,
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: const Color(0xFF1A365D),
                                                    side: const BorderSide(color: Color(0xFF1A365D)),
                                                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                                  ),
                                                  icon: const Icon(Icons.forward_to_inbox, size: 16),
                                                  label: Text(
                                                    role == 'HOD' ? 'Escalate to Dean' : 'Escalate to HOD',
                                                    style: const TextStyle(fontSize: 12.5),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  onPressed: () => _showCoordinatorEscalateDialog(context, req),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 42,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.danger,
                                                  side: const BorderSide(color: AppColors.danger),
                                                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                                ),
                                                icon: const Icon(Icons.close_rounded, size: 16),
                                                label: const Text('Reject', style: TextStyle(fontSize: 12.5)),
                                                onPressed: () => _showCoordinatorRejectDialog(context, req),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SizedBox(
                                              height: 42,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryBlue,
                                                  foregroundColor: Colors.white,
                                                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                                ),
                                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                                label: const Text('Approve', style: TextStyle(fontSize: 12.5)),
                                                onPressed: () => _showCoordinatorApproveDialog(context, req),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primaryBlue,
                                          side: const BorderSide(color: AppColors.primaryBlue),
                                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.visibility_outlined, size: 15),
                                        label: const Text('Details', style: TextStyle(fontSize: 12)),
                                        onPressed: () => RequestDetailsModal.show(context, req),
                                      ),
                                      if (canEscalate) ...[
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF1A365D),
                                            side: const BorderSide(color: Color(0xFF1A365D)),
                                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.forward_to_inbox, size: 15),
                                          label: Text(
                                            role == 'HOD' ? 'Escalate to Dean' : 'Escalate to HOD',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () => _showCoordinatorEscalateDialog(context, req),
                                        ),
                                      ],
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: const BorderSide(color: AppColors.danger),
                                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.close_rounded, size: 15),
                                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _showCoordinatorRejectDialog(context, req),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                                        label: const Text('Approve', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _showCoordinatorApproveDialog(context, req),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Completed / Awaiting Evidence / History
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlue,
                                        side: const BorderSide(color: AppColors.primaryBlue),
                                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.visibility_outlined, size: 15),
                                      label: const Text('View Full Dossier', style: TextStyle(fontSize: 12)),
                                      onPressed: () => RequestDetailsModal.show(context, req),
                                    ),
                                  ],
                                ),
                              );
                            },
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
