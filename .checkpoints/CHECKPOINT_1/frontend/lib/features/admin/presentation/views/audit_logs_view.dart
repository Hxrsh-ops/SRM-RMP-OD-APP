import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class AuditLogsView extends ConsumerWidget {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(adminAuditLogsProvider);
    final currentPage = ref.watch(auditLogPageProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
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
                  Text('Immutable System Audit Trail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Comprehensive immutable logs of every user action, role change, and status transition', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.file_download, size: 18),
                label: const Text('Export Audit CSV'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audit Logs CSV Export started')));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: auditAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading audit logs: $err')),
              data: (data) {
                final List<AuditLogEntry> items = data['items'];
                final int totalPages = data['total_pages'];

                return Column(
                  children: [
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Timestamp')),
                                DataColumn(label: Text('Actor')),
                                DataColumn(label: Text('Action')),
                                DataColumn(label: Text('Resource')),
                                DataColumn(label: Text('IP Address')),
                                DataColumn(label: Text('Details Payload')),
                              ],
                              rows: items.map((log) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(log.timestamp.length > 19 ? log.timestamp.substring(0, 19) : log.timestamp)),
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(log.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(log.actorRole, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    )),
                                    DataCell(Chip(label: Text(log.action, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: Colors.blue[50])),
                                    DataCell(Text('${log.resourceType} (${log.resourceId ?? "-"})')),
                                    DataCell(Text(log.ipAddress ?? '127.0.0.1')),
                                    DataCell(IconButton(
                                      icon: const Icon(Icons.code, size: 18),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Payload for ${log.action}'),
                                            content: Text(log.details != null ? log.details.toString() : 'No payload details'),
                                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                                          ),
                                        );
                                      },
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Log Records: ${data['total']}'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: currentPage > 1 ? () => ref.read(auditLogPageProvider.notifier).state = currentPage - 1 : null,
                            ),
                            Text('Page $currentPage of $totalPages'),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages ? () => ref.read(auditLogPageProvider.notifier).state = currentPage + 1 : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
