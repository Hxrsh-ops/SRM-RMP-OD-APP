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
      padding: const EdgeInsets.all(24),
      child: secAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading security center: $err')),
        data: (sec) {
          final List<SecurityEventEntry> events = sec['recent_events'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Security Control Center & Threat Monitoring', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Monitor authentication failures, locked accounts, role violations & security event timeline', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.refresh(adminSecuritySummaryProvider)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildSecStatCard('Failed Logins (24h)', '${sec['failed_logins_24h']}', Icons.lock_clock, Colors.orange),
                    const SizedBox(width: 16),
                    _buildSecStatCard('Locked Accounts', '${sec['locked_accounts_count']}', Icons.no_accounts, Colors.red),
                    const SizedBox(width: 16),
                    _buildSecStatCard('Role Violations', '${sec['role_violations_24h']}', Icons.gavel, Colors.purple),
                    const SizedBox(width: 16),
                    _buildSecStatCard('Upload Violations', '${sec['upload_violations_24h']}', Icons.upload_file, Colors.amber),
                  ],
                ),
                const SizedBox(height: 24),
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
                                trailing: Chip(
                                  label: Text(evt.severity, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  backgroundColor: evt.severity == 'WARNING' ? Colors.orange : Colors.blue,
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

  Widget _buildSecStatCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
