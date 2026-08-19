import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../../../core/network/providers/dio_provider.dart';

class AdminAnalyticsView extends ConsumerWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
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
                    Text('Enterprise Analytics & Performance Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Interactive departmental comparison, turnaround time analytics, and report export', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export Executive PDF Report'),
                  onPressed: () async {
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Generating Executive PDF Report from PostgreSQL...')),
                      );
                      await apiClient.get('/admin/reports/pdf');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Executive PDF Report compiled successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PDF Export Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            analyticsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Error loading analytics: $err', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(adminAnalyticsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                final depts = (data['department_comparisons'] as List?) ?? [];
                final trends = (data['monthly_trends'] as List?) ?? [];
                final totalReqs = data['total_od_requests'] ?? 0;

                if (totalReqs == 0) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'No Institutional Analytics Recorded Yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submit and process OD requests to generate live departmental approval metrics and monthly application volume trends.',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final deptCard = Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OD Approval Rate by Department', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (depts.isEmpty)
                          const Text('No department data available.', style: TextStyle(color: Colors.grey))
                        else
                          ...depts.map((d) {
                            final name = '${d['department_name']} (${d['code']})';
                            final pct = (d['percentage_value'] as num?)?.toDouble() ?? 0.0;
                            return _buildBarRow(name, pct, Colors.blue);
                          }),
                      ],
                    ),
                  ),
                );

                final trendCard = Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Application Volume Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (trends.isEmpty)
                          const Text('No volume trends recorded.', style: TextStyle(color: Colors.grey))
                        else
                          ...trends.map((t) {
                            final month = t['month_name'] as String;
                            final pct = (t['percentage_value'] as num?)?.toDouble() ?? 0.0;
                            final count = t['request_count'] ?? 0;
                            return _buildBarRow('$month ($count reqs)', pct, Colors.purple);
                          }),
                      ],
                    ),
                  ),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 850) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: deptCard),
                          const SizedBox(width: 16),
                          Expanded(child: trendCard),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        deptCard,
                        const SizedBox(height: 16),
                        trendCard,
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(String label, double pct, Color color) {
    final clampedPct = pct.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
              Text('${(clampedPct * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedPct,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
