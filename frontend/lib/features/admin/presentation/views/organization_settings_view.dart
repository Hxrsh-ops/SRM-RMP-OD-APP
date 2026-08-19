import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class OrganizationSettingsView extends ConsumerStatefulWidget {
  const OrganizationSettingsView({super.key});

  @override
  ConsumerState<OrganizationSettingsView> createState() => _OrganizationSettingsViewState();
}

class _OrganizationSettingsViewState extends ConsumerState<OrganizationSettingsView> {
  late TextEditingController _acadYearCtrl;
  late TextEditingController _maxSizeCtrl;
  late TextEditingController _jwtExprCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _hodAutoDaysCtrl;
  String _workflowMode = 'STANDARD';
  bool _allowCoordToHod = true;
  bool _allowHodToDean = true;
  bool _requireEvidence = true;
  bool _maintenanceMode = false;
  bool _initialized = false;

  void _initForm(OrganizationSettings s) {
    if (_initialized) return;
    _acadYearCtrl = TextEditingController(text: s.academicYear);
    _maxSizeCtrl = TextEditingController(text: s.maxFileSizeMb.toString());
    _jwtExprCtrl = TextEditingController(text: s.jwtExpirationMinutes.toString());
    _titleCtrl = TextEditingController(text: s.systemBrandingTitle);
    _hodAutoDaysCtrl = TextEditingController(text: s.hodAutoEscalationDays.toString());
    _workflowMode = s.workflowMode;
    _allowCoordToHod = s.allowCoordinatorEscalationToHod;
    _allowHodToDean = s.allowHodEscalationToDean;
    _requireEvidence = s.requireEvidence;
    _maintenanceMode = s.maintenanceMode;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminSettingsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
        data: (s) {
          _initForm(s);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organization Control & System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Configure approval workflow rules, upload quotas, security session limits, and branding', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save Settings'),
                      onPressed: _saveSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. DYNAMIC APPROVAL WORKFLOW POLICY MANAGER CARD
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1.5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_tree_rounded, color: Color(0xFF1A365D), size: 22),
                            SizedBox(width: 8),
                            Text('Dynamic Approval Workflow Policy Manager', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Control and change the institutional approval hierarchy across departments without modifying code.',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // Workflow Mode Dropdown
                        DropdownButtonFormField<String>(
                          value: _workflowMode,
                          decoration: const InputDecoration(
                            labelText: 'Institutional Approval Workflow Mode',
                            border: OutlineInputBorder(),
                            helperText: 'Select how OD requests flow through student, faculty, coordinator, and HOD stages.',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'STANDARD',
                              child: Text('Standard Workflow (Student → FA → Coordinator → Approved)'),
                            ),
                            DropdownMenuItem(
                              value: 'COMPREHENSIVE',
                              child: Text('Comprehensive Hierarchy (Student → FA → Coordinator → HOD → Approved)'),
                            ),
                            DropdownMenuItem(
                              value: 'DIRECT_HOD',
                              child: Text('Direct HOD Review (Student → FA → HOD → Approved)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _workflowMode = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Auto-Escalate Threshold
                        TextField(
                          controller: _hodAutoDaysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Auto-Escalate to HOD for Multi-Day ODs (Days)',
                            border: OutlineInputBorder(),
                            helperText: 'Set day threshold (e.g. 3). Requests with duration >= this value route to HOD. Set to 0 to disable.',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Escalation Rules Callout
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A365D).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1A365D).withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_outlined, color: Color(0xFF1A365D), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Escalation Protocol Policy: Coordinators can escalate requests to the Head of Department (HOD). Only the HOD possesses executive authority to escalate requests to the Dean for campus clearance. Deans cannot receive OD requests on their own.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF1A365D), fontWeight: FontWeight.w500, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Allow Coordinators to Escalate to HOD'),
                          subtitle: const Text('Coordinators can forward complex requests for HOD endorsement'),
                          value: _allowCoordToHod,
                          onChanged: (val) => setState(() => _allowCoordToHod = val),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Allow HOD to Escalate to Dean'),
                          subtitle: const Text('Only HOD can escalate high-profile / multi-tier requests to Executive Dean'),
                          value: _allowHodToDean,
                          onChanged: (val) => setState(() => _allowHodToDean = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Academic & Upload Rules Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Academic & Upload Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final acadField = TextField(
                              controller: _acadYearCtrl,
                              decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
                            );
                            final sizeField = TextField(
                              controller: _maxSizeCtrl,
                              decoration: const InputDecoration(labelText: 'Max Attachment File Size (MB)', border: OutlineInputBorder()),
                            );

                            if (constraints.maxWidth >= 600) {
                              return Row(
                                children: [
                                  Expanded(child: acadField),
                                  const SizedBox(width: 16),
                                  Expanded(child: sizeField),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                acadField,
                                const SizedBox(height: 16),
                                sizeField,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Require Post-Event Proof Evidence'),
                          subtitle: const Text('Enforce evidence document submission before completing OD requests'),
                          value: _requireEvidence,
                          onChanged: (val) => setState(() => _requireEvidence = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Security Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Security & Session Tokens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _jwtExprCtrl,
                          decoration: const InputDecoration(labelText: 'JWT Access Token Expiration (Minutes)', border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Branding & Maintenance Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('System Branding & Maintenance Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(labelText: 'Platform Header Title', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Maintenance Mode'),
                          subtitle: const Text('Restricts platform access strictly to Master Administrators'),
                          value: _maintenanceMode,
                          activeThumbColor: Colors.red,
                          onChanged: (val) => setState(() => _maintenanceMode = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveSettings() async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final updated = OrganizationSettings(
        academicYear: _acadYearCtrl.text.trim(),
        currentSemester: 'Even Semester',
        maxFileSizeMb: int.tryParse(_maxSizeCtrl.text) ?? 10,
        allowedFileTypes: ['pdf', 'jpg', 'png', 'jpeg'],
        requireEvidence: _requireEvidence,
        jwtExpirationMinutes: int.tryParse(_jwtExprCtrl.text) ?? 1440,
        notificationEmailEnabled: true,
        systemBrandingTitle: _titleCtrl.text.trim(),
        primaryColorHex: '#1A365D',
        maintenanceMode: _maintenanceMode,
        environmentInfo: 'Production-Ready Enterprise',
        workflowMode: _workflowMode,
        hodAutoEscalationDays: int.tryParse(_hodAutoDaysCtrl.text) ?? 0,
        allowCoordinatorEscalationToHod: _allowCoordToHod,
        allowHodEscalationToDean: _allowHodToDean,
      );
      await repo.updateOrganizationSettings(updated);
      ref.invalidate(adminSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow & System Settings updated successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
