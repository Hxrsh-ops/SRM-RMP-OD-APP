import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../admin/presentation/controllers/admin_controller.dart';
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

class _RequestDetailsModalState extends ConsumerState<RequestDetailsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAttachment(BuildContext context, String rawUrl, String fileName) async {
    final resolvedUrl = EnvConfig.resolveAttachmentUrl(rawUrl);
    if (resolvedUrl.isEmpty) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'Document "$fileName" path is unavailable.');
      }
      return;
    }

    try {
      final uri = Uri.parse(resolvedUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        AppSnackbar.showError(context, 'Unable to open "$fileName". URL: $resolvedUrl');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'Failed to download/open "$fileName": $e');
      }
    }
  }

  void _showCompletionProofDialog(BuildContext context, OdRequest req) {
    final summaryController = TextEditingController();
    List<PlatformFile> selectedFiles = [];
    bool isSubmitting = false;
    double uploadProgress = 0.0;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
            title: const Row(
              children: [
                Icon(Icons.assignment_turned_in_rounded, color: AppColors.primaryBlue, size: 22),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Submit Completion Proof',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request: ${req.id} • ${req.reason}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Completion Report Summary (Mandatory):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: summaryController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe event achievements, attendance outcome, certificates received...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Task 7 - Professional File Upload Zone
                  AppFileUploadZone(
                    selectedFiles: selectedFiles,
                    isUploading: isSubmitting,
                    uploadProgress: uploadProgress,
                    errorMessage: errorText,
                    onFilesPicked: (files) {
                      setDialogState(() {
                        selectedFiles.addAll(files);
                        errorText = null;
                      });
                    },
                    onFileRemoved: (file) {
                      setDialogState(() {
                        selectedFiles.remove(file);
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 44),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (summaryController.text.trim().isEmpty) {
                          setDialogState(() => errorText = 'A written completion summary is required.');
                          return;
                        }
                        if (selectedFiles.isEmpty) {
                          setDialogState(() => errorText = 'At least one proof document file must be attached.');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          uploadProgress = 0.4;
                          errorText = null;
                        });

                        final filesBytes = selectedFiles.map((f) => f.bytes!.toList()).toList();
                        final fileNames = selectedFiles.map((f) => f.name).toList();

                        final success = await ref.read(workflowControllerProvider.notifier).submitCompletionEvidence(
                              requestId: req.id,
                              completionSummary: summaryController.text.trim(),
                              filesBytes: filesBytes,
                              fileNames: fileNames,
                            );

                        setDialogState(() {
                          uploadProgress = 1.0;
                        });

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                        if (context.mounted) {
                          if (success) {
                            Navigator.pop(context); // Close details modal
                            AppSnackbar.showSuccess(
                              context,
                              'Completion proof uploaded successfully. Pending Faculty Advisor verification.',
                            );
                          } else {
                            final backendError = ref.read(workflowControllerProvider).errorMessage;
                            AppSnackbar.showError(
                              context,
                              backendError ?? 'Completion proof upload failed.',
                            );
                          }
                        }
                      },
                child: Text(isSubmitting ? 'Uploading...' : 'Submit Proof'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showShareClearanceDialog(BuildContext context, OdRequest req) {
    final emailCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
            title: const Row(
              children: [
                Icon(Icons.send_rounded, color: AppColors.primaryBlue, size: 22),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Share Verified Clearance',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request: ${req.id} • ${req.reason}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A365D))),
                  const SizedBox(height: 4),
                  Text('Send verified OD attendance proof directly to your course/subject teacher for attendance register entry.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: AppSpacing.md),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Course Teacher's Institutional Email",
                      hintText: "e.g. karthik@srmist.edu.in",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                      errorText: null,
                    ),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: "Optional Note for Subject Teacher",
                      hintText: "e.g. For Mathematics - Period 3 attendance",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(isSubmitting ? 'Verifying...' : 'Dispatch Clearance'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(() => errorMessage = 'Please enter a valid teacher institutional email.');
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        try {
                          final repo = ref.read(adminRepositoryProvider);
                          await repo.shareClearance(req.id, email, notes: noteCtrl.text.trim());
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            AppSnackbar.showSuccess(context, 'OD Attendance Clearance sent to $email successfully!');
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            final errStr = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
                            errorMessage = errStr;
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
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
    final pendingCount = studentRequests.where((r) => r.status == OdStatus.pendingFaculty || r.status == OdStatus.pendingCoordinator || r.status == OdStatus.pendingEvidenceFaculty || r.status == OdStatus.pendingEvidenceCoordinator).length;
    final rejectedCount = studentRequests.where((r) => r.status == OdStatus.rejected || r.status == OdStatus.facultyRejected).length;

    final isStudent = role == 'STUDENT';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final preApprovalDocs = req.attachments.where((a) => a.documentCategory != 'completion_evidence').toList();
    final completionDocs = req.attachments.where((a) => a.documentCategory == 'completion_evidence').toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
            // Drag Pill Handle
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.borderFull,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                          '${req.studentName} (${req.registerNumber})',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
            ),

            // Task 5 - Professional Section Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryBlue,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Details'),
                Tab(icon: Icon(Icons.attachment_rounded, size: 18), text: 'Documents'),
                Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Timeline'),
              ],
            ),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Academic & Event Details Section
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.md,
                      bottom: AppSpacing.lg + bottomInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Student Academic Information
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Student Academic Details',
                                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: req.residenceType == 'Hosteller' ? AppColors.accentYellow.withValues(alpha: 0.2) : AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      req.displayResidenceType,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: req.displayResidenceType == 'Hosteller' ? AppColors.warning : AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                req.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${req.registerNumber} • ${req.program} • ${req.yearSection}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
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

                        const SizedBox(height: AppSpacing.md),

                        // Section 2: Previous OD History
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

                        const SizedBox(height: AppSpacing.md),

                        // Section 3: Event Details
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

                        if (req.status == OdStatus.completed) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                                        SizedBox(width: 6),
                                        Text('Verified OD Attendance Clearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                                      icon: const Icon(Icons.send_rounded, size: 14),
                                      label: const Text('Share with Course Faculty'),
                                      onPressed: () => _showShareClearanceDialog(context, req),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text('All approvals and evidence verification are complete. Share digital clearance with your individual course/subject faculties for attendance entry.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tab 2: Documents & Proofs Section
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.md,
                      bottom: AppSpacing.lg + bottomInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post-Event Completion Report Card
                        if (req.completionSummary != null || req.status == OdStatus.approvedAwaitingEvidence || req.status == OdStatus.evidenceRevisionRequested) ...[
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Post-Event Completion Proof',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppStatusChip(label: req.statusDisplayLabel, statusType: req.status.statusType),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                if (req.completionSummary != null) ...[
                                  Text('Written Report Summary:', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                                  Text(req.completionSummary!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (req.completionSubmittedAt != null)
                                    Text('Submitted on: ${req.completionSubmittedAt.toString().split('.')[0]}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ] else ...[
                                  const Text('Event initial approval granted. Student must upload completion proof documents on/after event end date.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Student Action: Submit Completion Proof Button
                        if (isStudent && (req.status == OdStatus.approvedAwaitingEvidence || req.status == OdStatus.evidenceRevisionRequested)) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                              icon: const Icon(Icons.upload_file_rounded, size: 20),
                              label: const Text('Submit Completion Proof & Report'),
                              onPressed: () => _showCompletionProofDialog(context, req),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Parent Consent Document (Hosteller)
                        if (req.residenceType == 'Hosteller' || req.parentConsentUrl != null) ...[
                          const Text('Parent Consent Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                          const SizedBox(height: AppSpacing.xs),
                          InkWell(
                            onTap: () => _openAttachment(context, req.parentConsentUrl ?? '', 'Parent_Consent_Letter.pdf'),
                            borderRadius: AppRadius.borderMd,
                            child: Container(
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
                                        Text('Tap to view signed parent consent', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.open_in_new_rounded, color: AppColors.primaryBlue, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Pre-approval Documents
                        const Text('Pre-approval Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: AppSpacing.xs),
                        if (preApprovalDocs.isEmpty)
                          const AppEmptyState(
                            title: 'No Pre-approval Documents',
                            description: 'No supporting pre-approval PDF documents were attached.',
                          )
                        else
                          Column(
                            children: preApprovalDocs.map((att) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: InkWell(
                                  onTap: () => _openAttachment(context, att.fileUrl, att.fileName),
                                  borderRadius: AppRadius.borderMd,
                                  child: Container(
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
                                              Text(att.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text('Uploaded by ${att.uploadedBy} • ${att.sizeFormatted}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.open_in_new_rounded, color: AppColors.primaryBlue, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: AppSpacing.md),

                        // Completion Proof Documents Section
                        const Text('Post-Event Completion Proof Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                        const SizedBox(height: AppSpacing.xs),
                        if (completionDocs.isEmpty)
                          const AppEmptyState(
                            title: 'No Completion Documents Yet',
                            description: 'No post-event completion proof documents have been submitted.',
                          )
                        else
                          Column(
                            children: completionDocs.map((att) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: InkWell(
                                  onTap: () => _openAttachment(context, att.fileUrl, att.fileName),
                                  borderRadius: AppRadius.borderMd,
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: AppRadius.borderMd,
                                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_outlined, color: AppColors.primaryBlue, size: 20),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(att.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text('Proof Uploaded by ${att.uploadedBy} • ${att.sizeFormatted}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.open_in_new_rounded, color: AppColors.primaryBlue, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  // Tab 3: Timeline & Audit Trail Section
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.md,
                      bottom: AppSpacing.lg + bottomInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),
                ],
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
