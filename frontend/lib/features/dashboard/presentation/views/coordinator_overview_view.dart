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

class CoordinatorOverviewView extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToQueue;

  const CoordinatorOverviewView({super.key, this.onNavigateToQueue});

  @override
  ConsumerState<CoordinatorOverviewView> createState() => _CoordinatorOverviewViewState();
}

class _CoordinatorOverviewViewState extends ConsumerState<CoordinatorOverviewView> {
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
      if (mounted) setState(() => _analytics = res);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final workflowState = ref.watch(workflowControllerProvider);
    final allRequests = workflowState.requests;

    final pendingCoordCount = _analytics?['pending_coordinator_count'] ?? allRequests.where((r) => r.status == OdStatus.pendingCoordinator).length;
    final awaitingEvidenceCount = _analytics?['approved_awaiting_evidence_count'] ?? allRequests.where((r) => r.status == OdStatus.approvedAwaitingEvidence).length;
    final pendingEvidenceCount = _analytics?['pending_evidence_coordinator_count'] ?? allRequests.where((r) => r.status == OdStatus.pendingEvidenceCoordinator).length;
    final completedCount = _analytics?['completed_count'] ?? allRequests.where((r) => r.status == OdStatus.completed).length;

    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

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
            AppWelcomeHeader(
              userName: session?.name ?? 'Prof. Ramesh Kumar',
              subtitle: 'Department Coordinator • Real-time Executive Overview',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Metrics Cards
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
                        const Text('Coordinator Department Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                        Text(
                          'You have ${pendingCoordCount + pendingEvidenceCount} request(s) awaiting final department sign-off.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                    onPressed: widget.onNavigateToQueue,
                    child: const Text('Open Queue'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Department Submissions Stream
            const Text('Department Request Stream Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: AppSpacing.md),

            if (allRequests.isEmpty)
              const AppEmptyState(
                title: 'No Department Requests',
                description: 'No On Duty requests submitted in your department yet.',
              )
            else
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
              ),
          ],
        ),
      ),
    );
  }
}
