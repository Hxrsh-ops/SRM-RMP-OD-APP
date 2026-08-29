import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class DepartmentManagementView extends ConsumerWidget {
  const DepartmentManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(adminDepartmentsProvider);

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
                  Text('Department Topology & Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Configure college departments, assign coordinators, and monitor capacity metrics', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Department'),
                onPressed: () => _showDeptModal(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: deptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading departments: $err')),
              data: (depts) {
                if (depts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No Departments Configured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Click "Add Department" above to initialize your institutional department topology.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Department'),
                          onPressed: () => _showDeptModal(context, ref),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;
                    final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 950;
                    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
                    final aspectRatio = isMobile ? 1.6 : (isTablet ? 1.5 : 1.4);

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: depts.length,
                      itemBuilder: (context, index) {
                        final d = depts[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                                      child: Text(d.code, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _showDeptModal(context, ref, department: d),
                                    ),
                                  ],
                                ),
                                Text(d.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Coordinator: ${d.coordinatorName ?? "Unassigned"}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${d.studentCount} Students', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    Text('${d.facultyCount} Faculty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    Text('${d.approvalRate}% Appr Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeptModal(BuildContext context, WidgetRef ref, {AdminDepartment? department}) {
    final nameCtrl = TextEditingController(text: department?.name ?? '');
    final codeCtrl = TextEditingController(text: department?.code ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(department == null ? 'Create Department' : 'Edit Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Department Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Department Code (e.g. CSE)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(adminRepositoryProvider);
              if (department == null) {
                await repo.createDepartment({'name': nameCtrl.text.trim(), 'code': codeCtrl.text.trim()});
              } else {
                await repo.updateDepartment(department.id, {'name': nameCtrl.text.trim(), 'code': codeCtrl.text.trim()});
              }
              ref.invalidate(adminDepartmentsProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
