import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
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
    final analytics = ref.watch(workflowControllerProvider.select((s) => s.analytics));

    final pendingCoordCount = analytics?['pending_coordinator_count'] ?? allRequests.where((r) => r.status == OdStatus.pendingCoordinator || r.status == OdStatus.facultyApproved).length;
    final awaitingEvidenceCount = analytics?['approved_awaiting_evidence_count'] ?? allRequests.where((r) => r.status == OdStatus.approvedAwaitingEvidence).length;
    final pendingEvidenceCount = analytics?['pending_evidence_coordinator_count'] ?? allRequests.where((r) => r.status == OdStatus.pendingEvidenceCoordinator).length;
    final completedCount = analytics?['completed_count'] ?? allRequests.where((r) => r.status == OdStatus.completed).length;
    final totalCount = analytics?['total_submissions_count'] ?? allRequests.length;

    final role = session?.role ?? 'COORDINATOR';
    final isHod = role == 'HOD';
    final isDean = role == 'DEAN';

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
                  const Icon(Icons.verified_rounded, color: AppColors.primaryBlue, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(queueTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                        Text(
                          queueSubtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                            child: const Icon(Icons.domain_rounded, color: AppColors.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${req.studentName} (${req.registerNumber})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Advisor: ${req.facultyAdvisorName} • ${req.reason}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppStatusChip(label: req.status.displayName, statusType: req.status.statusType),
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
