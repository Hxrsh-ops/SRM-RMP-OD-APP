import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class StudentRegistryView extends ConsumerWidget {
  const StudentRegistryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(adminRepositoryProvider);

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
                  Text('Centralized Student Registry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('View academic student profiles, OD history timeline, attachments & faculty assignments', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download_sharp, size: 18),
                label: const Text('Export CSV Registry'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student CSV Registry Export initiated')));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: repo.getUsers(role: 'STUDENT', limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading registry: ${snapshot.error}'));
                }
                final items = (snapshot.data?['items'] as List<AdminUser>?) ?? [];

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Student Name & Reg No')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Program')),
                          DataColumn(label: Text('Year & Sec')),
                          DataColumn(label: Text('Assigned Faculty Advisor')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: items.map((s) {
                          return DataRow(
                            cells: [
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${s.username} • ${s.email}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              )),
                              DataCell(Text(s.departmentName ?? '—')),
                              DataCell(Text(s.program ?? '—')),
                              DataCell(Text(s.yearSection ?? '—')),
                              DataCell(Text(s.assignedFacultyName ?? 'Unassigned')),
                              DataCell(IconButton(
                                icon: const Icon(Icons.history_edu, color: Colors.blue),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => Container(
                                      padding: const EdgeInsets.all(24),
                                      height: 400,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('OD Application History for ${s.fullName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 12),
                                          Text('Register Number: ${s.username} | Department: ${s.departmentName ?? "SRM IST"}'),
                                          const Divider(height: 24),
                                          Expanded(
                                            child: Center(
                                              child: Text('Select or search OD requests for ${s.fullName} in Central OD Management.'),
                                            ),
                                          ),
                                        ],
                                      ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
