import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';

class SystemMonitoringView extends ConsumerWidget {
  const SystemMonitoringView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(adminMonitoringProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading system health: $err')),
        data: (h) {
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
                        Text('Real-time Infrastructure Monitoring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Monitor FastAPI API status, PostgreSQL connection pool, storage, memory & request latency', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Metrics',
                      onPressed: () => ref.refresh(adminMonitoringProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;
                    if (isMobile) {
                      return Column(
                        children: [
                          _buildHealthBadgeBox('API Gateway', h.apiStatus, Icons.api, Colors.green),
                          const SizedBox(height: 12),
                          _buildHealthBadgeBox('PostgreSQL Database', h.databaseStatus, Icons.storage, Colors.blue),
                          const SizedBox(height: 12),
                          _buildHealthBadgeBox('Overall Health', h.status, Icons.verified_user, Colors.teal),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _buildHealthBadgeBox('API Gateway', h.apiStatus, Icons.api, Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildHealthBadgeBox('PostgreSQL Database', h.databaseStatus, Icons.storage, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildHealthBadgeBox('Overall Health', h.status, Icons.verified_user, Colors.teal)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);
                    final aspectRatio = width > 900 ? 1.6 : (width > 600 ? 1.8 : 2.6);

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                      children: [
                        _buildMetricGauge('Active DB Connections', '${h.dbConnectionCount}', 'PostgreSQL Connection Pool Status', Colors.indigo),
                        _buildMetricGauge('Storage Usage', '${h.storageUsedMb} MB', 'Free: ${h.storageFreeMb} MB', Colors.purple),
                        _buildMetricGauge('CPU & Memory Load', '${h.cpuUsagePercent}% CPU', 'Memory Load: ${h.memoryUsagePercent}%', Colors.amber),
                        _buildMetricGauge('Response Latency', '${h.avgResponseTimeMs} ms', 'Average REST API Latency', Colors.teal),
                        _buildMetricGauge('24h Request Volume', '${h.totalRequests24h}', 'Failed Requests: ${h.failedRequests24h}', Colors.blue),
                        _buildMetricGauge('Connected Sessions', '${h.activeConnectedUsers}', 'Active Connected Users', Colors.green),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthBadgeBox(String name, String status, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGauge(String title, String mainValue, String subtext, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(mainValue, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtext, style: const TextStyle(fontSize: 11, color: Colors.black54), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
