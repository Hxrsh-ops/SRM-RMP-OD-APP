import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class FacultyManagementView extends ConsumerStatefulWidget {
  const FacultyManagementView({super.key});

  @override
  ConsumerState<FacultyManagementView> createState() => _FacultyManagementViewState();
}

class _FacultyManagementViewState extends ConsumerState<FacultyManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'NAME_ASC'; // NAME_ASC, NAME_DESC, STUDENTS_DESC, PENDING_DESC, SPEED_ASC

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(adminFacultyWorkloadProvider);

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
                  Text('Faculty Workload & Queue Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A365D))),
                  SizedBox(height: 4),
                  Text('Monitor approval queues, turnaround performance, and perform student reassignments', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Refresh Workload',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1A365D).withValues(alpha: 0.08),
                  foregroundColor: const Color(0xFF1A365D),
                ),
                onPressed: () => ref.refresh(adminFacultyWorkloadProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search by faculty name, email, department...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF1A365D)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF1A365D)),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1A365D), fontWeight: FontWeight.w600),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: 'NAME_ASC',
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Name (A-Z)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'NAME_DESC',
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Name (Z-A)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'STUDENTS_DESC',
                          child: Row(
                            children: [
                              Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Most Students'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'PENDING_DESC',
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Highest Queue'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'SPEED_ASC',
                          child: Row(
                            children: [
                              Icon(Icons.speed, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Fastest Speed'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sortBy = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: facultyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading faculty workload: $err')),
              data: (facultyList) {
                // Filter
                var list = facultyList.where((f) {
                  if (_searchQuery.isEmpty) return true;
                  return f.facultyName.toLowerCase().contains(_searchQuery) ||
                      f.email.toLowerCase().contains(_searchQuery) ||
                      (f.departmentName ?? '').toLowerCase().contains(_searchQuery);
                }).toList();

                // Sort
                switch (_sortBy) {
                  case 'NAME_ASC':
                    list.sort((a, b) => a.facultyName.toLowerCase().compareTo(b.facultyName.toLowerCase()));
                    break;
                  case 'NAME_DESC':
                    list.sort((a, b) => b.facultyName.toLowerCase().compareTo(a.facultyName.toLowerCase()));
                    break;
                  case 'STUDENTS_DESC':
                    list.sort((a, b) => b.assignedStudentsCount.compareTo(a.assignedStudentsCount));
                    break;
                  case 'PENDING_DESC':
                    list.sort((a, b) => b.pendingApprovalsCount.compareTo(a.pendingApprovalsCount));
                    break;
                  case 'SPEED_ASC':
                    list.sort((a, b) => a.avgTurnaroundHours.compareTo(b.avgTurnaroundHours));
                    break;
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No Faculty Found' : 'No faculty matched "$_searchQuery"',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A365D)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Provision faculty advisor accounts to monitor workloads here.'
                              : 'Try searching with a different name, email, or department.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

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
                        rows: list.map((f) {
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
                              DataCell(Text(f.departmentName ?? 'General')),
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
                  initialValue: targetId,
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
                    ref.invalidate(adminFacultyWorkloadProvider);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Students transferred successfully')));
                    }
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
