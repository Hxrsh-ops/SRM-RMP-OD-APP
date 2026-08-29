import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_models.dart';

class DepartmentManagementView extends ConsumerStatefulWidget {
  const DepartmentManagementView({super.key});

  @override
  ConsumerState<DepartmentManagementView> createState() => _DepartmentManagementViewState();
}

class _DepartmentManagementViewState extends ConsumerState<DepartmentManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'NAME_ASC'; // NAME_ASC, NAME_DESC, STUDENTS_DESC, OD_DESC, RATE_DESC

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(adminDepartmentsProvider);
    final sectionsAsync = ref.watch(classSectionsProvider);

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
                  Text('Department Topology & Class Sections', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A365D))),
                  SizedBox(height: 4),
                  Text('Configure college departments, class sections (Years 1-4, Sec A-Z), and assign Faculty Advisors', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Refresh Departments',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D).withValues(alpha: 0.08),
                      foregroundColor: const Color(0xFF1A365D),
                    ),
                    onPressed: () {
                      ref.invalidate(adminDepartmentsProvider);
                      ref.invalidate(classSectionsProvider);
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Department'),
                    onPressed: () => _showDeptModal(context, ref),
                  ),
                ],
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
                        hintText: 'Search departments by name or code...',
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
                          value: 'OD_DESC',
                          child: Row(
                            children: [
                              Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Most ODs'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'RATE_DESC',
                          child: Row(
                            children: [
                              Icon(Icons.percent, size: 16, color: Color(0xFF1A365D)),
                              SizedBox(width: 8),
                              Text('Sort: Highest Approval %'),
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
            child: deptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error loading departments: $err', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      onPressed: () => ref.refresh(adminDepartmentsProvider),
                    ),
                  ],
                ),
              ),
              data: (depts) {
                // Filter
                var list = depts.where((d) {
                  if (_searchQuery.isEmpty) return true;
                  return d.name.toLowerCase().contains(_searchQuery) ||
                      d.code.toLowerCase().contains(_searchQuery) ||
                      (d.coordinatorName ?? '').toLowerCase().contains(_searchQuery);
                }).toList();

                // Sort
                switch (_sortBy) {
                  case 'NAME_ASC':
                    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                    break;
                  case 'NAME_DESC':
                    list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
                    break;
                  case 'STUDENTS_DESC':
                    list.sort((a, b) => b.studentCount.compareTo(a.studentCount));
                    break;
                  case 'OD_DESC':
                    list.sort((a, b) => b.totalOdRequests.compareTo(a.totalOdRequests));
                    break;
                  case 'RATE_DESC':
                    list.sort((a, b) => b.approvalRate.compareTo(a.approvalRate));
                    break;
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No Departments Configured' : 'No departments matched "$_searchQuery"',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A365D)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Click "Add Department" above to initialize your institutional department topology.'
                              : 'Try searching with a different department name or code.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final allSections = sectionsAsync.value ?? [];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final d = list[index];
                        final deptSections = allSections.where((s) => s.departmentId == d.id).toList();

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFF1A365D).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text(d.code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A365D))),
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            d.name,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF1A365D),
                                            side: const BorderSide(color: Color(0xFF1A365D)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          icon: const Icon(Icons.class_outlined, size: 15),
                                          label: Text('Class Sections (${deptSections.length})', style: const TextStyle(fontSize: 12)),
                                          onPressed: () => _showSectionsModal(context, ref, d, deptSections),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          tooltip: 'Edit Department',
                                          onPressed: () => _showDeptModal(context, ref, department: d),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Coordinator: ${d.coordinatorName ?? "Unassigned"}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 12),
                                if (deptSections.isNotEmpty) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Active Class Sections (${deptSections.length}):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      if (deptSections.length > 3)
                                        InkWell(
                                          onTap: () => _showSectionsModal(context, ref, d, deptSections),
                                          child: Text(
                                            'Manage all (${deptSections.length}) →',
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ...deptSections.take(3).map((sec) {
                                        final hasFa = sec.facultyAdvisorName != null && sec.facultyAdvisorName!.isNotEmpty;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: hasFa ? Colors.blue.shade50 : Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: hasFa ? Colors.blue.shade200 : Colors.amber.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.school, size: 14, color: hasFa ? Colors.blue.shade800 : Colors.amber.shade800),
                                              const SizedBox(width: 6),
                                              Text('Year ${sec.academicYear} ${sec.section}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 6),
                                              Text(
                                                hasFa ? '• FA: ${sec.facultyAdvisorName}' : '• FA: Unassigned',
                                                style: TextStyle(fontSize: 11, color: hasFa ? Colors.blue.shade900 : Colors.amber.shade900),
                                              ),
                                              if (sec.studentCount > 0) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                                  child: Text('${sec.studentCount} std', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }),
                                      if (deptSections.length > 3)
                                        InkWell(
                                          onTap: () => _showSectionsModal(context, ref, d, deptSections),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A365D).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF1A365D).withValues(alpha: 0.2)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.more_horiz, size: 16, color: Color(0xFF1A365D)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '+${deptSections.length - 3} more sections',
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text('No class sections created yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () => _showAddSectionDialog(context, ref, d),
                                          child: const Text('+ Add Class Section', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
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
              ref.invalidate(classSectionsProvider);
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

  void _showSectionsModal(BuildContext context, WidgetRef ref, AdminDepartment dept, List<ClassSectionModel> sections) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DepartmentSectionsModalContent(
          dept: dept,
          fallbackSections: sections,
          isBottomSheet: true,
          onAddSection: (d) => _showAddSectionDialog(context, ref, d),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 680,
            child: DepartmentSectionsModalContent(
              dept: dept,
              fallbackSections: sections,
              isBottomSheet: false,
              onAddSection: (d) => _showAddSectionDialog(context, ref, d),
            ),
          ),
        ),
      );
    }
  }

  void _showAddSectionDialog(BuildContext context, WidgetRef ref, AdminDepartment dept) {
    int selectedYear = 2;
    final sectionCtrl = TextEditingController(text: 'Sec A');
    final batchCtrl = TextEditingController(text: '2024-2028');
    String? selectedFaId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final facultyWorkloads = ref.watch(adminFacultyWorkloadProvider).value ?? [];
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 550;

          return AlertDialog(
            title: Text('Add Class Section — ${dept.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: isMobile ? screenWidth * 0.95 : 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1st Year (Sem 1 & 2)')),
                      DropdownMenuItem(value: 2, child: Text('2nd Year (Sem 3 & 4)')),
                      DropdownMenuItem(value: 3, child: Text('3rd Year (Sem 5 & 6)')),
                      DropdownMenuItem(value: 4, child: Text('4th Year (Sem 7 & 8)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedYear = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sectionCtrl,
                    decoration: const InputDecoration(labelText: 'Section Name (e.g. Sec A, Sec B, Sec G)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: batchCtrl,
                    decoration: const InputDecoration(labelText: 'Batch (e.g. 2024-2028)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedFaId,
                    decoration: const InputDecoration(labelText: 'Assign Class Faculty Advisor', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Unassigned (Assign Later)', style: TextStyle(color: Colors.grey))),
                      ...facultyWorkloads.map((fac) => DropdownMenuItem<String?>(value: fac.facultyId, child: Text(fac.facultyName))),
                    ],
                    onChanged: (val) => setStateDialog(() => selectedFaId = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                onPressed: () async {
                  if (sectionCtrl.text.trim().isEmpty) return;
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.createClassSection({
                    'department_id': dept.id,
                    'academic_year': selectedYear,
                    'section': sectionCtrl.text.trim(),
                    'batch': batchCtrl.text.trim(),
                    'program': dept.name,
                    'faculty_advisor_id': selectedFaId,
                  });
                  ref.invalidate(classSectionsProvider);
                  ref.invalidate(adminDepartmentsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Create Section'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DepartmentSectionsModalContent extends ConsumerWidget {
  final AdminDepartment dept;
  final List<ClassSectionModel> fallbackSections;
  final bool isBottomSheet;
  final Function(AdminDepartment) onAddSection;

  const DepartmentSectionsModalContent({
    super.key,
    required this.dept,
    required this.fallbackSections,
    required this.isBottomSheet,
    required this.onAddSection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(classSectionsProvider);
    final facultyWorkloadsAsync = ref.watch(adminFacultyWorkloadProvider);
    final currentSections = sectionsAsync.value?.where((s) => s.departmentId == dept.id).toList() ?? fallbackSections;
    final facultyWorkloads = facultyWorkloadsAsync.value ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = isBottomSheet || screenWidth < 650;

    return Container(
      width: isMobile ? double.infinity : 680,
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBottomSheet)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Class Sections & FAs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dept.name} (${dept.code}) • ${currentSections.length} Sections',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A365D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Section', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  onAddSection(dept);
                },
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: currentSections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_outlined, size: 52, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No Class Sections Configured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text(
                          'Add sections (e.g. Year 2 Sec G) and assign Class Counselors / FAs.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A365D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create First Section'),
                          onPressed: () {
                            Navigator.pop(context);
                            onAddSection(dept);
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: currentSections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final s = currentSections[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF1A365D),
                                  foregroundColor: Colors.white,
                                  child: Text('Y${s.academicYear}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Year ${s.academicYear} — ${s.section}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Batch: ${s.batch ?? "N/A"} • ${s.studentCount} enrolled students', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  tooltip: 'Delete Section',
                                  onPressed: () async {
                                    final repo = ref.read(adminRepositoryProvider);
                                    await repo.deleteClassSection(s.id);
                                    ref.invalidate(classSectionsProvider);
                                    ref.invalidate(adminDepartmentsProvider);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  isExpanded: true,
                                  hint: const Text('Assign FA / Class Counselor', style: TextStyle(fontSize: 12)),
                                  value: s.facultyAdvisorId,
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Unassigned', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ),
                                    ...facultyWorkloads.map((fac) {
                                      return DropdownMenuItem<String?>(
                                        value: fac.facultyId,
                                        child: Text(fac.facultyName, style: const TextStyle(fontSize: 12)),
                                      );
                                    }),
                                  ],
                                  onChanged: (newFaId) async {
                                    final repo = ref.read(adminRepositoryProvider);
                                    await repo.assignClassSectionFA(s.id, facultyAdvisorId: newFaId);
                                    ref.invalidate(classSectionsProvider);
                                    ref.invalidate(adminDepartmentsProvider);
                                    ref.invalidate(adminUsersProvider);
                                  },
                                ),
                              ),
                            ),
                          ],
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
