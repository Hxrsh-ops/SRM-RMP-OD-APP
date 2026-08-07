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
                  Text('Centralized Student Registry', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('View academic student profiles, OD history timeline, attachments & faculty assignments', style: TextStyle(color: Colors.grey)),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download_sharp),
                label: const Text('Export CSV Registry'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student CSV Registry Export initiated')));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                              DataCell(Text(s.departmentName ?? 'CSE')),
                              DataCell(Text(s.program ?? 'B.Tech CSE')),
                              DataCell(Text(s.yearSection ?? '2nd Year')),
                              DataCell(Text(s.assignedFacultyName ?? 'Dr. Karthik B')),
                              DataCell(IconButton(
                                icon: const Icon(Icons.history_edu, color: Colors.blue),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => Container(
                                      padding: const EdgeInsets.all(24),
                                      height: 500,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('OD Application History for ${s.fullName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 12),
                                          const Text('Register Number: RA2511026020400 | Department: CSE'),
                                          const Divider(height: 24),
                                          const ListTile(
                                            leading: Icon(Icons.check_circle, color: Colors.green),
                                            title: Text('National AI Hackathon 2026'),
                                            subtitle: Text('Status: COMPLETED • Duration: 3 Days'),
                                          ),
                                          const ListTile(
                                            leading: Icon(Icons.check_circle, color: Colors.green),
                                            title: Text('Smart India Hackathon Finals'),
                                            subtitle: Text('Status: COMPLETED • Duration: 3 Days'),
                                          ),
                                          const ListTile(
                                            leading: Icon(Icons.hourglass_top, color: Colors.orange),
                                            title: Text('State Robotics Championship'),
                                            subtitle: Text('Status: PENDING_FACULTY • Duration: 2 Days'),
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
