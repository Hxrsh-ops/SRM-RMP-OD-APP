import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../admin/presentation/controllers/admin_controller.dart';
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
                  final updatedReq = ref.read(workflowControllerProvider).requests.where((r) => r.id == request.id).firstOrNull;
                  final isCompleted = updatedReq?.status == OdStatus.completed;
                  final successMsg = isEvidenceMode
                      ? (isCompleted
                          ? 'Completion evidence verified & Final OD granted for ${request.id}!'
                          : 'Completion evidence verified & forwarded for department review.')
                      : 'Faculty approval submitted for ${request.id} & forwarded for department review.';
                  AppSnackbar.showSuccess(context, successMsg);
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
    final sharedClearancesAsync = ref.watch(sharedClearancesProvider);
    final sharedList = sharedClearancesAsync.value ?? [];
    final isMobile = ResponsiveLayout.isMobile(context);

    final initialPending = allRequests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.submitted).toList();
    final evidencePending = allRequests.where((r) => r.status == OdStatus.pendingEvidenceFaculty).toList();

    final activeRequestsList = (_activeTab == 0 ? initialPending : evidencePending).where((r) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return r.studentName.toLowerCase().contains(q) || r.registerNumber.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q);
    }).toList();

    final activeSharedList = sharedList.where((s) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return s.studentName.toLowerCase().contains(q) || s.studentRegNo.toLowerCase().contains(q) || s.reason.toLowerCase().contains(q);
    }).toList();

    Widget buildFacultyMetricCard({
      required String title,
      required String value,
      required IconData icon,
      required AppStatusType statusType,
      required int tabIndex,
    }) {
      final isSelected = _activeTab == tabIndex;
      Color activeColor;
      switch (statusType) {
        case AppStatusType.warning:
          activeColor = Colors.orange.shade700;
          break;
        case AppStatusType.info:
          activeColor = const Color(0xFF1A365D);
          break;
        case AppStatusType.success:
          activeColor = Colors.green.shade700;
          break;
        default:
          activeColor = const Color(0xFF1A365D);
      }

      return InkWell(
        onTap: () => setState(() => _activeTab = tabIndex),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 20, color: activeColor),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? activeColor : Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(workflowControllerProvider.notifier).loadAllData();
        ref.invalidate(sharedClearancesProvider);
      },
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
              'Review student attendance eligibility, approve On Duty submissions, and acknowledge course clearances',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: buildFacultyMetricCard(
                    title: 'Initial Approvals',
                    value: '${initialPending.length}',
                    icon: Icons.assignment_late_outlined,
                    statusType: AppStatusType.warning,
                    tabIndex: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildFacultyMetricCard(
                    title: 'Evidence Verification',
                    value: '${evidencePending.length}',
                    icon: Icons.fact_check_outlined,
                    statusType: AppStatusType.info,
                    tabIndex: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildFacultyMetricCard(
                    title: 'Shared Clearances',
                    value: '${sharedList.length}',
                    icon: Icons.mark_email_read_outlined,
                    statusType: AppStatusType.success,
                    tabIndex: 2,
                  ),
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

            if (_activeTab == 2)
              // Tab 3: Shared Clearances List
              if (activeSharedList.isEmpty)
                const AppEmptyState(
                  title: 'No Shared Course Clearances',
                  description: 'Students who share their verified OD attendance clearances with you will appear here.',
                )
              else
                Column(
                  children: activeSharedList.map((share) {
                    final isAck = share.isAcknowledged;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isAck ? Colors.green.shade200 : Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isAck ? Colors.green.shade50 : const Color(0xFF1A365D).withValues(alpha: 0.08),
                                  child: Icon(
                                    isAck ? Icons.check_circle : Icons.school_rounded,
                                    size: 20,
                                    color: isAck ? Colors.green.shade700 : const Color(0xFF1A365D),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        share.studentName,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${share.studentRegNo} • ${share.studentYearSection ?? ""} (${share.studentProgram ?? ""})',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAck ? Colors.green.shade50 : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isAck ? Colors.green.shade200 : Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAck ? Icons.check_circle : Icons.verified,
                                        size: 12,
                                        color: isAck ? Colors.green.shade800 : Colors.blue.shade800,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAck ? 'Acknowledged' : 'Clearance Verified',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: isAck ? Colors.green.shade900 : Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Event Details Box
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF1A365D)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${share.reason} (${share.startDate} to ${share.endDate})',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A365D).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${share.durationDays} ${share.durationDays == 1 ? "Day" : "Days"}',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                                      ),
                                    ),
                                  ],
                                ),
                                if (share.notes != null && share.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.notes_rounded, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Student Note: "${share.notes}"',
                                          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11.5, color: Colors.grey.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1),

                          // Action Footer
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: isAck
                                ? Row(
                                    children: [
                                      Icon(Icons.verified_rounded, size: 16, color: Colors.green.shade700),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Attendance Exemption Recorded • Synced with ERP',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 15, color: Colors.orange.shade800),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Grant attendance waiver for course',
                                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1A365D),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.check_circle_outline, size: 16),
                                        label: const Text('Acknowledge Attendance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          final repo = ref.read(adminRepositoryProvider);
                                          await repo.acknowledgeClearance(share.id);
                                          ref.invalidate(sharedClearancesProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Attendance acknowledged for ${share.studentName}.'),
                                                backgroundColor: Colors.green.shade700,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
            else
              // Tab 0 & 1: Initial Approvals & Evidence Verification
              if (activeRequestsList.isEmpty)
                AppEmptyState(
                  title: _activeTab == 0 ? 'No Pending Initial Reviews' : 'No Evidence Pending Verification',
                  description: _activeTab == 0
                      ? 'All student OD requests assigned to your advisor queue have been reviewed.'
                      : 'No student completion proof documents are currently awaiting your verification.',
                )
              else
                Column(
                  children: activeRequestsList.map((req) {
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
                              AppStatusChip(label: req.statusDisplayLabel, statusType: req.status.statusType),
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
                          const SizedBox(height: AppSpacing.md),

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
