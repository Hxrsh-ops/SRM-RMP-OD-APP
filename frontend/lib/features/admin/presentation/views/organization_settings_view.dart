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
  bool _requireEvidence = true;
  bool _maintenanceMode = false;
  bool _initialized = false;

  void _initForm(OrganizationSettings s) {
    if (_initialized) return;
    _acadYearCtrl = TextEditingController(text: s.academicYear);
    _maxSizeCtrl = TextEditingController(text: s.maxFileSizeMb.toString());
    _jwtExprCtrl = TextEditingController(text: s.jwtExpirationMinutes.toString());
    _titleCtrl = TextEditingController(text: s.systemBrandingTitle);
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
                        Text('Configure platform policies, upload rules, JWT session limits, branding, and maintenance mode', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

                // Settings Cards Grid
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Academic & Workflow Policy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      );
      await repo.updateOrganizationSettings(updated);
      ref.invalidate(adminSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
