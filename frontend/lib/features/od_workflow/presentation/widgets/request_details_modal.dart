import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import '../../domain/entities/od_request.dart';
import '../../domain/entities/od_status.dart';
import '../controllers/workflow_controller.dart';

class RequestDetailsModal extends ConsumerStatefulWidget {
  final OdRequest request;

  const RequestDetailsModal({super.key, required this.request});

  static void show(BuildContext context, OdRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestDetailsModal(request: request),
    );
  }

  @override
  ConsumerState<RequestDetailsModal> createState() => _RequestDetailsModalState();
}

class _RequestDetailsModalState extends ConsumerState<RequestDetailsModal> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final role = session?.role ?? 'STUDENT';

    final req = widget.request;
    final workflowState = ref.watch(workflowControllerProvider);
    final studentRequests = workflowState.requests.where((r) => r.studentId == req.studentId || r.registerNumber == req.registerNumber).toList();
    final approvedCount = studentRequests.where((r) => r.status == OdStatus.completed).length;
    final pendingCount = studentRequests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.pendingCoordinator).length;
    final rejectedCount = studentRequests.where((r) => r.status == OdStatus.rejected || r.status == OdStatus.facultyRejected).length;

    final isFaculty = role == 'FACULTY_ADVISOR';
    final isCoordinator = role == 'COORDINATOR';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.id,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Submitted by ${req.studentName} (${req.registerNumber})',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppStatusChip(label: req.status.displayName, statusType: req.status.statusType),
                ],
              ),
            ),

            // Scrollable Body Content with Keyboard Avoidance Padding
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: AppSpacing.lg + bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Academic & Residence Info Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Student Academic Details', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: req.residenceType == 'Hosteller' ? AppColors.accentYellow.withValues(alpha: 0.2) : AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  req.residenceType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: req.residenceType == 'Hosteller' ? AppColors.warning : AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text('${req.program} • ${req.yearSection}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const AppDivider(),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Attendance %', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    Text('${req.attendancePercentage}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CGPA', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    Text('${req.cgpa}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Previous OD History Summary (Sections 7, 8, 9)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Student Previous OD History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatBadge(label: 'Total', value: '${studentRequests.length}', color: AppColors.primaryBlue),
                              _StatBadge(label: 'Approved', value: '$approvedCount', color: AppColors.success),
                              _StatBadge(label: 'Pending', value: '$pendingCount', color: AppColors.warning),
                              _StatBadge(label: 'Rejected', value: '$rejectedCount', color: AppColors.danger),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Event & Request Summary
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reason for Request', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                          Text(req.reason, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const AppDivider(),
                          Text('Dates & Duration', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                          Text(
                            '${req.startDate.toString().split(' ')[0]} to ${req.endDate.toString().split(' ')[0]} (${req.durationDays} Days)',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const AppDivider(),
                          Text('Purpose / Venue / Organizer', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                          Text('${req.purpose} • ${req.venue} • ${req.organizer}', style: theme.textTheme.bodyMedium),
                          if (req.additionalNotes != null && req.additionalNotes!.isNotEmpty) ...[
                            const AppDivider(),
                            Text('Additional Notes', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                            Text(req.additionalNotes!, style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Faculty Review Details for Coordinator (Section 8)
                    if (isCoordinator || req.status == OdStatus.pendingCoordinator || req.status == OdStatus.completed) ...[
                      AppInfoCard(
                        title: 'Faculty Advisor Review Details',
                        description: 'Advisor: ${req.facultyAdvisorName}\nApproval Status: ${req.status == OdStatus.pendingCoordinator || req.status == OdStatus.completed ? "Approved" : "Pending"}\nFaculty Remarks: Verified student academic eligibility & event invitation.',
                        icon: Icons.verified_user_outlined,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Parent Consent Document (Mandatory for Hosteller)
                    if (req.residenceType == 'Hosteller' || req.parentConsentUrl != null) ...[
                      const Text('Parent Consent Document (Mandatory for Hosteller)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 22),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Parent_Consent_Letter.pdf', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Signed & Verified Parent Consent Form', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Icon(Icons.download_rounded, color: AppColors.primaryBlue, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Supporting Documents Section
                    const Text('Supporting Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: AppSpacing.xs),
                    if (req.attachments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.borderMd,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.attachment_outlined, color: AppColors.textSecondary, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'No supporting documents attached.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: req.attachments.map((att) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_outlined, color: AppColors.danger, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        att.fileName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Uploaded by ${att.uploadedBy} • ${att.sizeFormatted}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.download_rounded, color: AppColors.primaryBlue, size: 20),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // Workflow Timeline Audit Trail Section
                    const Text('Approval Timeline Audit Trail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: AppSpacing.sm),
                    Column(
                      children: req.timeline.map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 14, color: AppColors.primaryBlue),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(
                                      '${step.actorName} (${step.actorRole}) • ${step.timestamp.toString().split('.')[0]}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    if (step.note != null && step.note!.isNotEmpty)
                                      Text(
                                        'Note: "${step.note}"',
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.primaryBlue),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    // Actions area for Faculty Advisor or Coordinator
                    if (isFaculty && (req.status == OdStatus.pendingFaculty || req.status == OdStatus.submitted)) ...[
                      const AppDivider(),
                      const Text('Faculty Decision Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _commentController,
                        labelText: 'Faculty Comment / Remarks',
                        hintText: 'e.g. Verified student academic eligibility.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppSecondaryButton(
                              label: 'Reject Request',
                              onPressed: () {
                                ref.read(workflowControllerProvider.notifier).processFacultyAction(
                                      requestId: req.id,
                                      facultyId: session?.username ?? 'FA1001',
                                      facultyName: session?.name ?? 'Dr. Karthik B',
                                      approve: false,
                                      comment: _commentController.text,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Approve Request',
                              onPressed: () {
                                ref.read(workflowControllerProvider.notifier).processFacultyAction(
                                      requestId: req.id,
                                      facultyId: session?.username ?? 'FA1001',
                                      facultyName: session?.name ?? 'Dr. Karthik B',
                                      approve: true,
                                      comment: _commentController.text,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else if (isCoordinator && (req.status == OdStatus.pendingCoordinator || req.status == OdStatus.facultyApproved)) ...[
                      const AppDivider(),
                      const Text('Coordinator Decision Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _commentController,
                        labelText: 'Coordinator Remarks',
                        hintText: 'e.g. Approved for official department records.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppOutlineButton(
                              label: 'Needs Revision',
                              onPressed: () {
                                ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                                      requestId: req.id,
                                      coordinatorId: session?.username ?? 'CO1001',
                                      coordinatorName: session?.name ?? 'Prof. Ramesh Kumar',
                                      approve: false,
                                      returnForCorrection: true,
                                      comment: _commentController.text,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Final Approve',
                              onPressed: () {
                                ref.read(workflowControllerProvider.notifier).processCoordinatorAction(
                                      requestId: req.id,
                                      coordinatorId: session?.username ?? 'CO1001',
                                      coordinatorName: session?.name ?? 'Prof. Ramesh Kumar',
                                      approve: true,
                                      comment: _commentController.text,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
