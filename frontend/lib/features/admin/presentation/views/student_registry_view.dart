import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';
import 'user_management_view.dart';

class StudentRegistryView extends ConsumerStatefulWidget {
  const StudentRegistryView({super.key});

  @override
  ConsumerState<StudentRegistryView> createState() => _StudentRegistryViewState();
}

class _StudentRegistryViewState extends ConsumerState<StudentRegistryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'NAME_ASC'; // NAME_ASC, NAME_DESC, REG_ASC, DEPT_ASC, PROG_ASC

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Centralized Student Registry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A365D))),
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
                        hintText: 'Search by student name, reg no, email, department...',
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
                          value: 'REG_ASC',
                          child: Row(
                            children: [
                              Icon(Icons.numbers, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Register No'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'DEPT_ASC',
                          child: Row(
                            children: [
                              Icon(Icons.business, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Department'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'PROG_ASC',
                          child: Row(
                            children: [
                              Icon(Icons.school, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Program'),
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
            child: FutureBuilder<Map<String, dynamic>>(
              future: repo.getUsers(role: 'STUDENT', limit: 100),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading registry: ${snapshot.error}'));
                }
                final rawItems = (snapshot.data?['items'] as List<AdminUser>?) ?? [];

                // Filter items
                var items = rawItems.where((s) {
                  if (_searchQuery.isEmpty) return true;
                  return s.fullName.toLowerCase().contains(_searchQuery) ||
                      s.username.toLowerCase().contains(_searchQuery) ||
                      s.email.toLowerCase().contains(_searchQuery) ||
                      (s.departmentName ?? '').toLowerCase().contains(_searchQuery) ||
                      (s.program ?? '').toLowerCase().contains(_searchQuery) ||
                      (s.yearSection ?? '').toLowerCase().contains(_searchQuery) ||
                      (s.assignedFacultyName ?? '').toLowerCase().contains(_searchQuery);
                }).toList();

                // Sort items
                switch (_sortBy) {
                  case 'NAME_ASC':
                    items.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
                    break;
                  case 'NAME_DESC':
                    items.sort((a, b) => b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase()));
                    break;
                  case 'REG_ASC':
                    items.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
                    break;
                  case 'DEPT_ASC':
                    items.sort((a, b) => (a.departmentName ?? '').compareTo(b.departmentName ?? ''));
                    break;
                  case 'PROG_ASC':
                    items.sort((a, b) => (a.program ?? '').compareTo(b.program ?? ''));
                    break;
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No Students Found' : 'No students matched "$_searchQuery"',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A365D)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Provision student accounts via Users & Access to view them here.'
                              : 'Try searching with a different name, register number, or department.',
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
                                tooltip: 'View OD Application History',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => UserRecordsDialog(user: s),
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
