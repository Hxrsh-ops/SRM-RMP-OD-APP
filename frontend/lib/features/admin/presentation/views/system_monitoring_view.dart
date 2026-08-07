import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class SystemMonitoringView extends ConsumerWidget {
  const SystemMonitoringView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(adminMonitoringProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading system health: $err')),
        data: (h) {
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
                        Text('Real-time Infrastructure Monitoring', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Monitor FastAPI API status, PostgreSQL connection pool, storage, memory & request latency', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.refresh(adminMonitoringProvider)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildHealthBadge('API Gateway', h.apiStatus, Icons.api, Colors.green),
                    const SizedBox(width: 16),
                    _buildHealthBadge('PostgreSQL Database', h.databaseStatus, Icons.storage, Colors.blue),
                    const SizedBox(width: 16),
                    _buildHealthBadge('Overall Health', h.status, Icons.verified_user, Colors.teal),
                  ],
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    _buildMetricGauge('Active DB Connections', '${h.dbConnectionCount}', 'PostgreSQL Connection Pool Status', Colors.indigo),
                    _buildMetricGauge('Storage Usage', '${h.storageUsedMb} MB', 'Free: ${h.storageFreeMb} MB', Colors.purple),
                    _buildMetricGauge('CPU & Memory Load', '${h.cpuUsagePercent}% CPU', 'Memory Load: ${h.memoryUsagePercent}%', Colors.amber),
                    _buildMetricGauge('Response Latency', '${h.avgResponseTimeMs} ms', 'Average REST API Latency', Colors.teal),
                    _buildMetricGauge('24h Request Volume', '${h.totalRequests24h}', 'Failed Requests: ${h.failedRequests24h}', Colors.blue),
                    _buildMetricGauge('Connected Sessions', '${h.activeConnectedUsers}', 'Active Connected Users', Colors.green),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthBadge(String name, String status, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(status, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGauge(String title, String mainValue, String subtext, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(mainValue, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtext, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
