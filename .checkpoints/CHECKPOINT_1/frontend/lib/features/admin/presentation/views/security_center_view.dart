import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class SecurityCenterView extends ConsumerWidget {
  const SecurityCenterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secAsync = ref.watch(adminSecuritySummaryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: secAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading security center: $err')),
        data: (sec) {
          final List<SecurityEventEntry> events = sec['recent_events'];

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
                        Text('Security Control Center & Threat Monitoring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Monitor authentication failures, locked accounts, role violations & security event timeline', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (events.isNotEmpty)
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                            icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                            label: const Text('Clear All Logs'),
                            onPressed: () => _confirmClearAllSecurity(context, ref),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh Security',
                          onPressed: () => ref.refresh(adminSecuritySummaryProvider),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 900 ? 4 : (width > 550 ? 2 : 1);
                    final aspectRatio = width > 900 ? 1.8 : (width > 550 ? 2.2 : 3.2);

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                      children: [
                        _buildSecStatCard('Failed Logins (24h)', '${sec['failed_logins_24h']}', Icons.lock_clock, Colors.orange),
                        _buildSecStatCard('Locked Accounts', '${sec['locked_accounts_count']}', Icons.no_accounts, Colors.red),
                        _buildSecStatCard('Role Violations', '${sec['role_violations_24h']}', Icons.gavel, Colors.purple),
                        _buildSecStatCard('Upload Violations', '${sec['upload_violations_24h']}', Icons.upload_file, Colors.amber),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Security Event Stream', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (events.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No security violations or threats recorded.', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final evt = events[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: evt.severity == 'WARNING' ? Colors.orange[100] : Colors.blue[100],
                                  child: Icon(Icons.shield, color: evt.severity == 'WARNING' ? Colors.orange[900] : Colors.blue[900]),
                                ),
                                title: Text(evt.eventType, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('User: ${evt.username ?? "Unknown"} • IP: ${evt.ipAddress ?? "127.0.0.1"} • ${evt.timestamp}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(evt.severity, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                      backgroundColor: evt.severity == 'WARNING' ? Colors.orange : Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      tooltip: 'Delete security event',
                                      onPressed: () async {
                                        final repo = ref.read(adminRepositoryProvider);
                                        await repo.deleteSecurityEvent(evt.id);
                                        ref.refresh(adminSecuritySummaryProvider);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
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

  void _confirmClearAllSecurity(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Security Logs?'),
        content: const Text('Are you sure you want to clear all security event records?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(adminRepositoryProvider);
              await repo.clearAllSecurityEvents();
              ref.refresh(adminSecuritySummaryProvider);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecStatCard(String title, String val, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                  Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
