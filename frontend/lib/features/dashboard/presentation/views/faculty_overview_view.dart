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

class FacultyOverviewView extends ConsumerWidget {
  final VoidCallback? onNavigateToQueue;

  const FacultyOverviewView({super.key, this.onNavigateToQueue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final allRequests = ref.watch(workflowControllerProvider.select((s) => s.requests));

    final initialPending = allRequests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.submitted).toList();
    final evidencePending = allRequests.where((r) => r.status == OdStatus.pendingEvidenceFaculty).toList();
    final totalAssigned = allRequests.length;

    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppWelcomeHeader(
              userName: session?.name ?? 'Faculty Advisor',
              subtitle: 'Faculty Advisor • Class Counselor Overview',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Metrics Row
            if (isDesktop)
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Total Student Submissions',
                      value: '$totalAssigned',
                      icon: Icons.analytics_outlined,
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
                          title: 'Initial Pending',
                          value: '${initialPending.length}',
                          icon: Icons.assignment_late_outlined,
                          statusType: AppStatusType.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppMetricCard(
                          title: 'Evidence Pending',
                          value: '${evidencePending.length}',
                          icon: Icons.fact_check_outlined,
                          statusType: AppStatusType.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppMetricCard(
                    title: 'Total Submissions',
                    value: '$totalAssigned',
                    icon: Icons.analytics_outlined,
                    statusType: AppStatusType.success,
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.xl),

            // Quick Action Banner to Queue
            AppCard(
              backgroundColor: AppColors.primaryContainer,
              child: Row(
                children: [
                  const Icon(Icons.rate_review_outlined, color: AppColors.primaryBlue, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Advisor Approval Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                        Text(
                          'You have ${initialPending.length + evidencePending.length} total request(s) awaiting your verification.',
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

            // Recent Submissions Overview Stream
            const Text('Recent Assigned Student Submissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: AppSpacing.md),

            if (allRequests.isEmpty)
              const AppEmptyState(
                title: 'No Student Requests',
                description: 'No On Duty requests have been assigned to your advisor account yet.',
              )
            else
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
                                child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryBlue, size: 20),
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
                                      req.registerNumber,
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
              ),
          ],
        ),
      ),
    );
  }
}
