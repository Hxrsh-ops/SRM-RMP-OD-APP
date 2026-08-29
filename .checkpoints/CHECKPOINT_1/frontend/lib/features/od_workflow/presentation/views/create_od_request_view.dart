import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import '../../domain/entities/attachment_item.dart';
import '../controllers/workflow_controller.dart';

class CreateOdRequestView extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const CreateOdRequestView({super.key, this.onSuccess});

  @override
  ConsumerState<CreateOdRequestView> createState() => _CreateOdRequestViewState();
}

class _CreateOdRequestViewState extends ConsumerState<CreateOdRequestView> {
  final _formKey = GlobalKey<FormState>();

  final _reasonController = TextEditingController();
  final _purposeController = TextEditingController();
  final _venueController = TextEditingController();
  final _organizerController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _durationDays = 0;

  String _residenceType = 'Day Scholar';
  String? _parentConsentUrl;

  final List<AttachmentItem> _uploadedAttachments = [];
  bool _isUploadingFile = false;
  String? _uploadError;

  @override
  void dispose() {
    _reasonController.dispose();
    _purposeController.dispose();
    _venueController.dispose();
    _organizerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateDuration() {
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        setState(() {
          _durationDays = 0;
        });
        return;
      }
      final diff = _endDate!.difference(_startDate!).inDays + 1;
      setState(() {
        _durationDays = diff > 0 ? diff : 0;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = isStart ? (_startDate ?? today) : (_endDate ?? _startDate ?? today);
    final firstDate = isStart ? today : (_startDate ?? today);
    final lastDate = today.add(const Duration(days: 90));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
        _calculateDuration();
      });
    }
  }

  Future<void> _pickAndUploadFile({bool isParentConsent = false}) async {
    if (!isParentConsent && _uploadedAttachments.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 supporting attachments allowed per OD request to conserve storage quota.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingFile = true;
      _uploadError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final name = file.name;

        if (bytes == null || bytes.isEmpty) {
          throw Exception('Failed to read file bytes.');
        }

        if (bytes.length > 10 * 1024 * 1024) {
          throw Exception('File exceeds 10 MB maximum upload limit.');
        }

        final uploadedItem = await ref.read(workflowControllerProvider.notifier).uploadAttachment(
              fileBytes: bytes,
              fileName: name,
              documentCategory: isParentConsent ? 'parent_consent' : 'supporting_document',
            );

        if (uploadedItem != null) {
          setState(() {
            if (isParentConsent) {
              _parentConsentUrl = uploadedItem.fileUrl;
              // Replace old parent consent if already in list
              _uploadedAttachments.removeWhere((a) => a.documentCategory == 'parent_consent');
            }
            _uploadedAttachments.add(uploadedItem);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File "${uploadedItem.fileName}" uploaded successfully.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          throw Exception('Backend returned empty response for file upload.');
        }
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
        });
      }
    }
  }

  void _clearForm() {
    _reasonController.clear();
    _purposeController.clear();
    _venueController.clear();
    _organizerController.clear();
    _notesController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _durationDays = 0;
      _residenceType = 'Day Scholar';
      _parentConsentUrl = null;
      _uploadedAttachments.clear();
      _uploadError = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid Start and End dates for On Duty.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before Start date.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_residenceType == 'Hosteller' && (_parentConsentUrl == null || _parentConsentUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hostellers must upload a Parent Consent Letter before submitting.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final session = ref.read(authControllerProvider).session;
    final studentId = session?.userId ?? '';
    final studentName = session?.name ?? '';
    final regNo = session?.username ?? '';

    final success = await ref.read(workflowControllerProvider.notifier).submitRequest(
          studentId: studentId,
          studentName: studentName,
          registerNumber: regNo,
          reason: _reasonController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          durationDays: _durationDays,
          purpose: _purposeController.text.trim(),
          venue: _venueController.text.trim(),
          organizer: _organizerController.text.trim(),
          additionalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          residenceType: _residenceType,
          parentConsentUrl: _parentConsentUrl,
          attachments: _uploadedAttachments,
        );

    if (mounted) {
      if (success) {
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('On Duty Request submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSuccess?.call();
      } else {
        final errorMsg = ref.read(workflowControllerProvider).errorMessage ?? 'Submission failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg (Entered form data preserved)'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = ref.watch(workflowControllerProvider.select((s) => s.isLoading));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit On Duty Request',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Fill out event information, select dates, and attach required supporting evidence',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Event Details Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Event Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                  const SizedBox(height: AppSpacing.md),

                  // Reason / Title
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title / Reason *',
                      hintText: 'e.g. IEEE International Conference / Hackathon 2026',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter event title or reason' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Purpose
                  TextFormField(
                    controller: _purposeController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Event Purpose *',
                      hintText: 'Describe presentation role or competition participation...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please specify event purpose' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 550;
                      final venueField = TextFormField(
                        controller: _venueController,
                        decoration: const InputDecoration(
                          labelText: 'Venue / Location *',
                          hintText: 'e.g. Anna University Campus',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter venue' : null,
                      );
                      final organizerField = TextFormField(
                        controller: _organizerController,
                        decoration: const InputDecoration(
                          labelText: 'Organizing Authority *',
                          hintText: 'e.g. Department of CSE',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter organizer' : null,
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: venueField),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: organizerField),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          venueField,
                          const SizedBox(height: AppSpacing.md),
                          organizerField,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Dates & Duration Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('On Duty Dates & Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      final startDateField = InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                          ),
                          child: Text(
                            _startDate != null ? _startDate.toString().split(' ')[0] : 'Select Start Date',
                            style: TextStyle(color: _startDate != null ? Colors.black : AppColors.textSecondary),
                          ),
                        ),
                      );
                      final endDateField = InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                          ),
                          child: Text(
                            _endDate != null ? _endDate.toString().split(' ')[0] : 'Select End Date',
                            style: TextStyle(color: _endDate != null ? Colors.black : AppColors.textSecondary),
                          ),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: startDateField),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: endDateField),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          startDateField,
                          const SizedBox(height: AppSpacing.md),
                          endDateField,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.25),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Calculated Duration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('$_durationDays Days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Residence & Parent Consent
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Residence Type & Parent Consent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _residenceType,
                    decoration: const InputDecoration(
                      labelText: 'Residence Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Day Scholar', child: Text('Day Scholar')),
                      DropdownMenuItem(value: 'Hosteller', child: Text('Hosteller')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _residenceType = val);
                    },
                  ),
                  if (_residenceType == 'Hosteller') ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                              SizedBox(width: AppSpacing.xs),
                              Text('Parent Consent Letter Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Hosteller students must upload an official parent/guardian consent letter.', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: AppSpacing.sm),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
                            onPressed: _isUploadingFile ? null : () => _pickAndUploadFile(isParentConsent: true),
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: Text(_parentConsentUrl != null ? 'Parent Consent Attached ✓' : 'Upload Parent Consent Letter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Real Supporting Evidence Upload Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const Text('Supporting Documents & Certificates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                      ElevatedButton.icon(
                        onPressed: _isUploadingFile ? null : () => _pickAndUploadFile(isParentConsent: false),
                        icon: const Icon(Icons.attach_file_rounded, size: 18),
                        label: const Text('Add File'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Supported formats: PDF, PNG, JPG (Max 10 MB per file)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.md),

                  if (_isUploadingFile)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: AppSpacing.md),
                          Text('Uploading file to server...'),
                        ],
                      ),
                    ),

                  if (_uploadError != null)
                    Text('Upload Error: $_uploadError', style: const TextStyle(color: AppColors.danger, fontSize: 12)),

                  if (_uploadedAttachments.isEmpty && !_isUploadingFile)
                    const Text('No supporting documents attached yet.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary))
                  else
                    Column(
                      children: _uploadedAttachments.map((att) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryBlue, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    att.fileName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(att.sizeBytes / 1024).toStringAsFixed(1)} KB',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _uploadedAttachments.remove(att);
                                      if (_parentConsentUrl == att.fileUrl) {
                                        _parentConsentUrl = null;
                                      }
                                    });
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
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: isSubmitting ? null : _submitForm,
                icon: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(isSubmitting ? 'Submitting Application...' : 'Submit On Duty Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
