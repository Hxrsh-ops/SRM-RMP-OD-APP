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

class StudentDashboardView extends ConsumerWidget {
  const StudentDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final requests = ref.watch(workflowControllerProvider.select((s) => s.requests));

    final pendingCount = requests.where((r) =>
        r.status == OdStatus.pendingFaculty ||
        r.status == OdStatus.pendingCoordinator ||
        r.status == OdStatus.pendingEvidenceFaculty ||
        r.status == OdStatus.pendingEvidenceCoordinator).length;

    final approvedCount = requests.where((r) =>
        r.status == OdStatus.completed ||
        r.status == OdStatus.approvedAwaitingEvidence).length;

    final rejectedCount = requests.where((r) =>
        r.status == OdStatus.rejected ||
        r.status == OdStatus.facultyRejected ||
        r.status == OdStatus.revisionRequested ||
        r.status == OdStatus.evidenceRevisionRequested).length;

    final totalCount = requests.length;

    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

    Widget buildMetricsSection() {
      final cards = [
        Expanded(
          child: AppMetricCard(
            title: 'Pending ODs',
            value: '$pendingCount',
            icon: Icons.hourglass_top_rounded,
            statusType: AppStatusType.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppMetricCard(
            title: 'Approved ODs',
            value: '$approvedCount',
            icon: Icons.check_circle_outline_rounded,
            statusType: AppStatusType.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppMetricCard(
            title: 'Rejected / Revision',
            value: '$rejectedCount',
            icon: Icons.cancel_outlined,
            statusType: AppStatusType.rejected,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppMetricCard(
            title: 'Total Requests',
            value: '$totalCount',
            icon: Icons.assignment_outlined,
            statusType: AppStatusType.info,
          ),
        ),
      ];

      if (isDesktop) {
        return Row(children: cards);
      }

      return Column(
        children: [
          Row(children: [cards[0], cards[1]]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [cards[2], cards[3]]),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(workflowControllerProvider.notifier).loadAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppWelcomeHeader(
              userName: session?.name ?? 'Student',
              subtitle: session?.program ?? (session?.username ?? 'SRM Ramapuram'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4 Metrics Cards
            buildMetricsSection(),

            const SizedBox(height: AppSpacing.xl),

            // Assigned Advisor Banner
            AppInfoCard(
              title: 'Assigned Faculty Advisor',
              description: '${session?.assignedFacultyName ?? "Faculty Advisor"} — Class Counselor',
              icon: Icons.person_search_outlined,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recent Requests Content
            if (isDesktop && requests.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent OD Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: AppSpacing.md),
                          ...requests.take(4).map((req) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppClickableCard(
                                onTap: () => RequestDetailsModal.show(context, req),
                                child: Row(
                                  children: [
                                    const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 20),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(req.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('${req.id} • ${req.durationDays} Days', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    AppStatusChip(label: req.status.displayName, statusType: req.status.statusType),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Latest OD Timeline Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: AppSpacing.md),
                          Text('ID: ${requests.first.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                          Text(requests.first.purpose, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const AppDivider(),
                          ...requests.first.timeline.map((step) {
                            final showActor = step.actorName.isNotEmpty &&
                                step.actorName != 'System' &&
                                !step.title.toLowerCase().contains(step.actorName.toLowerCase());
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step.title,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        if (showActor)
                                          Text(
                                            '${step.actorName} (${step.actorRole})',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              const Text('Recent OD Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),
              if (requests.isEmpty)
                const AppEmptyState(
                  title: 'No OD Requests Found',
                  description: 'You have not submitted any On Duty requests yet.',
                )
              else
                Column(
                  children: requests.take(4).map((req) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppClickableCard(
                        onTap: () => RequestDetailsModal.show(context, req),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${req.id} • ${req.durationDays} Days', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            AppStatusChip(label: req.status.displayName, statusType: req.status.statusType),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
