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

class StudentDashboardView extends ConsumerStatefulWidget {
  const StudentDashboardView({super.key});

  @override
  ConsumerState<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends ConsumerState<StudentDashboardView> {
  int _selectedFilterIndex = 3; // 0 = Pending, 1 = Approved, 2 = Rejected/Revision, 3 = All

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final requests = ref.watch(workflowControllerProvider.select((s) => s.requests));

    final pendingList = requests.where((r) =>
        r.status == OdStatus.pendingFaculty ||
        r.status == OdStatus.pendingCoordinator ||
        r.status == OdStatus.pendingEvidenceFaculty ||
        r.status == OdStatus.pendingEvidenceCoordinator).toList();

    final approvedList = requests.where((r) =>
        r.status == OdStatus.completed ||
        r.status == OdStatus.approvedAwaitingEvidence).toList();

    final rejectedList = requests.where((r) =>
        r.status == OdStatus.rejected ||
        r.status == OdStatus.facultyRejected ||
        r.status == OdStatus.revisionRequested ||
        r.status == OdStatus.evidenceRevisionRequested).toList();

    final pendingCount = pendingList.length;
    final approvedCount = approvedList.length;
    final rejectedCount = rejectedList.length;
    final totalCount = requests.length;

    List<OdRequest> filteredList;
    String filterLabel;
    switch (_selectedFilterIndex) {
      case 0:
        filteredList = pendingList;
        filterLabel = 'Pending Review';
        break;
      case 1:
        filteredList = approvedList;
        filterLabel = 'Approved / Completed';
        break;
      case 2:
        filteredList = rejectedList;
        filterLabel = 'Rejected / Revision';
        break;
      case 3:
      default:
        filteredList = requests;
        filterLabel = 'All Requests';
        break;
    }

    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

    Widget buildClickableCard({
      required String title,
      required String value,
      required IconData icon,
      required Color color,
      required int index,
    }) {
      final isSelected = _selectedFilterIndex == index;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedFilterIndex = index),
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
                  value,
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

    Widget buildMetricsSection() {
      final cards = [
        Expanded(
          child: buildClickableCard(
            title: 'Pending ODs',
            value: '$pendingCount',
            icon: Icons.hourglass_top_rounded,
            color: Colors.amber.shade800,
            index: 0,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: buildClickableCard(
            title: 'Approved ODs',
            value: '$approvedCount',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green.shade700,
            index: 1,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: buildClickableCard(
            title: 'Rejected / Revision',
            value: '$rejectedCount',
            icon: Icons.cancel_outlined,
            color: Colors.red.shade700,
            index: 2,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: buildClickableCard(
            title: 'Total Requests',
            value: '$totalCount',
            icon: Icons.assignment_outlined,
            color: const Color(0xFF1A365D),
            index: 3,
          ),
        ),
      ];

      if (isDesktop) {
        return Row(children: cards);
      }

      return Column(
        children: [
          Row(children: [cards[0], cards[1]]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [cards[2], cards[3]]),
        ],
      );
    }

    final awaitingEvidenceRequests = requests.where((r) => r.status == OdStatus.approvedAwaitingEvidence).toList();

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

            if (awaitingEvidenceRequests.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, color: Colors.amber.shade800, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proof Submission Required (${awaitingEvidenceRequests.length} OD)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your On Duty request is approved. Please upload your event participation certificate or photo proof to grant final OD attendance.',
                            style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Upload Proof'),
                      onPressed: () => RequestDetailsModal.show(context, awaitingEvidenceRequests.first),
                    ),
                  ],
                ),
              ),
            ],

            // 4 Interactive Metrics Cards
            buildMetricsSection(),

            const SizedBox(height: AppSpacing.md),

            // Active Filter Chip Indicator
            if (_selectedFilterIndex != 3) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A365D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1A365D).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF1A365D)),
                        const SizedBox(width: 4),
                        Text(
                          'Filtered by: $filterLabel (${filteredList.length})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A365D)),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _selectedFilterIndex = 3),
                          child: const Icon(Icons.cancel, size: 14, color: Color(0xFF1A365D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.md),

            // Assigned Advisor Banner
            AppInfoCard(
              title: 'Assigned Faculty Advisor',
              description: '${session?.assignedFacultyName ?? "Faculty Advisor"} — Class Counselor',
              icon: Icons.person_search_outlined,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Filtered Requests Content Area
            if (filteredList.isEmpty)
              AppEmptyState(
                title: _selectedFilterIndex == 3 ? 'No OD Requests Found' : 'No $filterLabel Requests',
                description: _selectedFilterIndex == 3
                    ? 'You have not submitted any On Duty requests yet.'
                    : 'No On Duty requests found matching the "$filterLabel" category.',
              )
            else if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedFilterIndex == 3 ? 'Recent OD Requests' : '$filterLabel Requests',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A365D)),
                              ),
                              Text(
                                '${filteredList.length} Total',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...filteredList.map((req) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppClickableCard(
                                onTap: () => RequestDetailsModal.show(context, req),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEBF8FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 20),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            req.reason,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${req.id} • ${req.durationDays} Days • ${req.purpose}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                          const Text(
                            'Latest OD Timeline Preview',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A365D)),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'ID: ${filteredList.first.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            filteredList.first.purpose,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const AppDivider(),
                          ...filteredList.first.timeline.map((step) {
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
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
              Text(
                _selectedFilterIndex == 3 ? 'Recent OD Requests' : '$filterLabel Requests',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A365D)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Column(
                children: filteredList.take(6).map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppClickableCard(
                      onTap: () => RequestDetailsModal.show(context, req),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.reason,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text('${req.id} • ${req.durationDays} Days', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          AppStatusChip(label: req.statusDisplayLabel, statusType: req.status.statusType),
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
