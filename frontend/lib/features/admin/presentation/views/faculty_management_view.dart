import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class FacultyManagementView extends ConsumerWidget {
  const FacultyManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(adminFacultyWorkloadProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faculty Workload & Queue Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Monitor approval queues, turnaround performance, and perform student reassignments', style: TextStyle(color: Colors.grey)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(adminFacultyWorkloadProvider),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: facultyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading faculty workload: $err')),
              data: (facultyList) {
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Faculty Member')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Assigned Students')),
                          DataColumn(label: Text('Pending Queue')),
                          DataColumn(label: Text('Approved / Rejected')),
                          DataColumn(label: Text('Avg Response Speed')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: facultyList.map((f) {
                          return DataRow(
                            cells: [
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(f.facultyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(f.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              )),
                              DataCell(Text(f.departmentName ?? 'CSE')),
                              DataCell(Chip(label: Text('${f.assignedStudentsCount} Students', style: const TextStyle(fontSize: 11)), backgroundColor: Colors.blue[50])),
                              DataCell(Chip(label: Text('${f.pendingApprovalsCount} Pending', style: TextStyle(fontSize: 11, color: f.pendingApprovalsCount > 0 ? Colors.orange[900] : Colors.grey[700])), backgroundColor: f.pendingApprovalsCount > 0 ? Colors.amber[100] : Colors.grey[100])),
                              DataCell(Text('${f.totalApprovedCount} Appr / ${f.totalRejectedCount} Rej')),
                              DataCell(Text('${f.avgTurnaroundHours} hrs')),
                              DataCell(ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                                icon: const Icon(Icons.swap_horiz, size: 16),
                                label: const Text('Transfer Queue'),
                                onPressed: () => _showTransferModal(context, ref, f, facultyList),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTransferModal(BuildContext context, WidgetRef ref, FacultyWorkload source, List<FacultyWorkload> all) {
    String? targetId = all.firstWhere((element) => element.facultyId != source.facultyId, orElse: () => all.first).facultyId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Transfer Students from ${source.facultyName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Currently assigned: ${source.assignedStudentsCount} students'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: targetId,
                  decoration: const InputDecoration(labelText: 'Target Faculty Member', border: OutlineInputBorder()),
                  items: all.where((f) => f.facultyId != source.facultyId).map((f) {
                    return DropdownMenuItem(value: f.facultyId, child: Text('${f.facultyName} (${f.departmentName})'));
                  }).toList(),
                  onChanged: (val) => setState(() => targetId = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (targetId != null) {
                    final repo = ref.read(adminRepositoryProvider);
                    await repo.transferFacultyStudents(source.facultyId, targetId!, null);
                    ref.refresh(adminFacultyWorkloadProvider);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students transferred successfully')));
                  }
                },
                child: const Text('Transfer'),
              ),
            ],
          );
        },
      ),
    );
  }
}
