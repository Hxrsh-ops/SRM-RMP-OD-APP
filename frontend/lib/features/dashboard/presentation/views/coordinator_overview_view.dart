import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../admin/presentation/controllers/admin_controller.dart';
import '../../../authentication/authentication.dart';
import '../../../od_workflow/domain/entities/od_status.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/widgets/request_details_modal.dart';

class CoordinatorOverviewView extends ConsumerWidget {
  final VoidCallback? onNavigateToQueue;

  const CoordinatorOverviewView({super.key, this.onNavigateToQueue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final allRequests = ref.watch(workflowControllerProvider.select((s) => s.requests));

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

    final roleLabel = isDean ? 'Executive Dean' : (isHod ? 'Head of Department' : 'Department Coordinator');
    final roleSubtitle = isDean
        ? 'Executive Dean • Campus-Wide Clearance Overview'
        : (isHod ? 'Head of Department • Department Executive Overview' : 'Department Coordinator • Real-time Executive Overview');
    final queueTitle = isDean
        ? 'Executive Dean Clearance Queue'
        : (isHod ? 'Head of Department Approval Queue' : 'Coordinator Department Queue');
    final pendingTotal = pendingCoordCount + pendingEvidenceCount;
    final queueSubtitle = isDean
        ? 'You have $pendingTotal request(s) escalated for Executive Dean sign-off.'
        : (isHod
            ? 'You have $pendingTotal request(s) awaiting HOD clearance.'
            : 'You have $pendingTotal request(s) awaiting final department sign-off.');

    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

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
            AppWelcomeHeader(
              userName: session?.name ?? roleLabel,
              subtitle: roleSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Metrics Row
            if (isDesktop)
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
                      title: 'Pending Proof Verification',
                      value: '$pendingEvidenceCount',
                      icon: Icons.fact_check_outlined,
                      statusType: AppStatusType.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Completed & Granted',
                      value: '$completedCount',
                      icon: Icons.verified_user_outlined,
                      statusType: AppStatusType.success,
                    ),
                  ),
                ],
              )
            else
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
              ),

            const SizedBox(height: AppSpacing.xl),

            // Quick Action Banner
            AppCard(
              backgroundColor: AppColors.primaryContainer,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          queueTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          queueSubtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    onPressed: onNavigateToQueue,
                    child: const Text('Open Queue'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Department Submissions Stream
            const Text('Department Request Stream Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: AppSpacing.md),

            if (allRequests.isNotEmpty)
              Column(
                children: allRequests.take(5).map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppClickableCard(
                      onTap: () => RequestDetailsModal.show(context, req),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                                child: const Icon(Icons.domain_rounded, color: AppColors.primaryBlue, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req.studentName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${req.registerNumber} • Advisor: ${req.facultyAdvisorName}',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AppStatusChip(label: req.statusDisplayLabel, statusType: req.status.statusType),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Event: ${req.reason} • ${req.durationDays} Days (${req.startDate.toString().split(" ")[0]})',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
            else if (totalCount > 0)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.task_alt_rounded, color: Colors.green.shade700, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Approval Queue Cleared',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All department On Duty requests requiring your action are processed. ($completedCount Completed, $awaitingEvidenceCount Awaiting Proof)',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const AppEmptyState(
                title: 'No Department Requests',
                description: 'No On Duty requests submitted in your department yet.',
              ),
          ],
        ),
      ),
    );
  }
}
