import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import 'faculty_advisees_view.dart';

class DepartmentStudentDirectoryView extends ConsumerStatefulWidget {
  const DepartmentStudentDirectoryView({super.key});

  @override
  ConsumerState<DepartmentStudentDirectoryView> createState() => _DepartmentStudentDirectoryViewState();
}

class _DepartmentStudentDirectoryViewState extends ConsumerState<DepartmentStudentDirectoryView> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _directoryStudents = [];
  List<Map<String, dynamic>> _searchResults = [];
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0 = All, 1 = Active, 2 = Pending Evidence, 3 = Completed
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchDirectory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDirectory({bool isSilent = false}) async {
    if (!isSilent && _directoryStudents.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final repo = ref.read(workflowRepositoryProvider);
      final list = await repo.getDepartmentStudentDirectory(limit: 30);
      if (mounted) {
        setState(() {
          _directoryStudents = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repo = ref.read(workflowRepositoryProvider);
        final results = await repo.searchStudents(query.trim(), limit: 30);
        if (mounted && _searchQuery == query) {
          setState(() {
            _searchResults = results;
          });
        }
      } catch (_) {}
    });
  }

  void _exportDirectoryCsv(List<Map<String, dynamic>> students) {
    final buffer = StringBuffer();
    buffer.writeln('Register Number,Student Name,Department,Program,Year & Section,Email,CGPA,Attendance %,Assigned Faculty,Active ODs,Total ODs,Latest OD ID,Latest Event,Start Date,End Date,Duration Days,Latest Status,Overdue Proof');
    for (final st in students) {
      final lr = st['latest_od_request'] as Map<String, dynamic>?;
      final isOverdue = lr?['is_evidence_overdue'] == true ? 'YES (${lr?['days_past_event']}d)' : 'NO';
      buffer.writeln(
        '"${st['username'] ?? ''}",'
        '"${st['full_name'] ?? ''}",'
        '"${st['department_name'] ?? ''}",'
        '"${st['program'] ?? ''}",'
        '"${st['year_section'] ?? ''}",'
        '"${st['email'] ?? ''}",'
        '${st['cgpa'] ?? ''},'
        '${st['attendance_percentage'] ?? ''},'
        '"${st['assigned_faculty_name'] ?? ''}",'
        '${st['active_od_count'] ?? 0},'
        '${st['total_od_count'] ?? 0},'
        '"${lr?['id'] ?? ''}",'
        '"${lr?['reason'] ?? ''}",'
        '"${lr?['start_date'] ?? ''}",'
        '"${lr?['end_date'] ?? ''}",'
        '${lr?['duration_days'] ?? ''},'
        '"${lr?['status'] ?? ''}",'
        '"$isOverdue"'
      );
    }
    FileDownloadHelper.downloadCsv(
      csvContent: buffer.toString(),
      filename: 'student_directory_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student Directory CSV report downloaded successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _inspectStudentRecords(Map<String, dynamic> student) {
    AdviseeRecordsInspectionDialog.show(context, student);
  }

  String _formatStatusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'PENDING_FACULTY':
        return 'Pending FA Approval';
      case 'FACULTY_APPROVED':
        return 'FA Approved';
      case 'PENDING_COORDINATOR':
        return 'Pending Coordinator / HOD';
      case 'APPROVED_AWAITING_EVIDENCE':
        return 'Awaiting Proof';
      case 'PENDING_EVIDENCE_FACULTY':
        return 'Pending FA Proof';
      case 'PENDING_EVIDENCE_COORDINATOR':
        return 'Pending Proof Review';
      case 'COMPLETED':
        return 'Completed';
      case 'REJECTED':
      case 'FACULTY_REJECTED':
        return 'Rejected';
      case 'REVISION_REQUESTED':
      case 'EVIDENCE_REVISION_REQUESTED':
        return 'Revision';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  Color _getStatusBadgeColor(String raw) {
    switch (raw.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'PENDING_FACULTY':
      case 'PENDING_COORDINATOR':
      case 'PENDING_EVIDENCE_FACULTY':
      case 'PENDING_EVIDENCE_COORDINATOR':
        return Colors.orange.shade800;
      case 'APPROVED_AWAITING_EVIDENCE':
      case 'FACULTY_APPROVED':
        return Colors.blue.shade700;
      case 'REJECTED':
      case 'FACULTY_REJECTED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);
    final session = ref.watch(authControllerProvider).session;
    final isSearching = _searchQuery.trim().isNotEmpty;
    final displayList = isSearching ? _searchResults : _directoryStudents;

    final filteredList = displayList.where((st) {
      if (_selectedFilterIndex == 1) {
        return ((st["active_od_count"] as int?) ?? 0) > 0;
      } else if (_selectedFilterIndex == 2) {
        final lr = st['latest_od_request'] as Map<String, dynamic>?;
        final s = (lr?['status'] as String?)?.toUpperCase() ?? '';
        return s == 'APPROVED_AWAITING_EVIDENCE' || s.contains('PENDING_EVIDENCE');
      } else if (_selectedFilterIndex == 3) {
        final lr = st['latest_od_request'] as Map<String, dynamic>?;
        final s = (lr?['status'] as String?)?.toUpperCase() ?? '';
        final total = (st["total_od_count"] as int?) ?? 0;
        final active = (st["active_od_count"] as int?) ?? 0;
        return s == 'COMPLETED' || (total > 0 && active == 0);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchDirectory,
        child: ListView(
          padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.md),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Directory & OD Records',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recent student submissions directory (Top 30) & Global search for ${session?.role ?? "Approver"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Export CSV'),
                  onPressed: () => _exportDirectoryCsv(displayList),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _fetchDirectory,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Directory',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary Metrics
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: _MetricPill(
                      icon: Icons.school_outlined,
                      color: AppColors.primaryBlue,
                      label: 'Students in Queue',
                      value: '${_directoryStudents.length}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricPill(
                      icon: Icons.assignment_late_outlined,
                      color: Colors.orange.shade800,
                      label: 'Active In-Flight ODs',
                      value: '${_directoryStudents.fold<int>(0, (sum, st) => sum + ((st["active_od_count"] as int?) ?? 0))}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricPill(
                      icon: Icons.history_edu_outlined,
                      color: Colors.green.shade700,
                      label: 'Total Submissions',
                      value: '${_directoryStudents.fold<int>(0, (sum, st) => sum + ((st["total_od_count"] as int?) ?? 0))}',
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricPill(
                          icon: Icons.school_outlined,
                          color: AppColors.primaryBlue,
                          label: 'Students',
                          value: '${_directoryStudents.length}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MetricPill(
                          icon: Icons.assignment_late_outlined,
                          color: Colors.orange.shade800,
                          label: 'Active ODs',
                          value: '${_directoryStudents.fold<int>(0, (sum, st) => sum + ((st["active_od_count"] as int?) ?? 0))}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MetricPill(
                          icon: Icons.history_edu_outlined,
                          color: Colors.green.shade700,
                          label: 'Total ODs',
                          value: '${_directoryStudents.fold<int>(0, (sum, st) => sum + ((st["total_od_count"] as int?) ?? 0))}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search any student by Register Number, Name, Email, Program, Section...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: _selectedFilterIndex == 0,
                    label: Text('All Students (${displayList.length})'),
                    onSelected: (_) => setState(() => _selectedFilterIndex = 0),
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedFilterIndex == 1,
                    label: Text('Active In-Flight ODs (${displayList.where((s) => ((s['active_od_count'] as int?) ?? 0) > 0).length})'),
                    onSelected: (_) => setState(() => _selectedFilterIndex = 1),
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange.shade900,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedFilterIndex == 2,
                    label: Text('Pending Evidence (${displayList.where((s) {
                      final lr = s['latest_od_request'] as Map<String, dynamic>?;
                      final sState = (lr?['status'] as String?)?.toUpperCase() ?? '';
                      return sState == 'APPROVED_AWAITING_EVIDENCE' || sState.contains('PENDING_EVIDENCE');
                    }).length})'),
                    onSelected: (_) => setState(() => _selectedFilterIndex = 2),
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade900,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedFilterIndex == 3,
                    label: Text('Completed History (${displayList.where((s) {
                      final lr = s['latest_od_request'] as Map<String, dynamic>?;
                      return (lr?['status'] as String?)?.toUpperCase() == 'COMPLETED';
                    }).length})'),
                    onSelected: (_) => setState(() => _selectedFilterIndex = 3),
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green.shade900,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section Label
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSearching ? Icons.search_rounded : Icons.dynamic_feed_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSearching
                          ? 'Search Results (${filteredList.length})'
                          : 'Recent Request Directory (${filteredList.length} Students)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                if (!isSearching)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'De-duplicated • Latest at top',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Content List
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: AppSpacing.md),
                      Text('Failed to load student directory: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(onPressed: _fetchDirectory, child: const Text('Try Again')),
                    ],
                  ),
                ),
              )
            else if (filteredList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      Icon(
                        isSearching ? Icons.person_search_outlined : Icons.folder_open_outlined,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isSearching
                            ? 'No student found matching "$_searchQuery".'
                            : 'No student OD submissions found matching selected filter.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final student = filteredList[index];
                  final name = (student['full_name'] ?? 'Student').toString();
                  final regNo = (student['username'] ?? '').toString();
                  final program = (student['program'] ?? '').toString();
                  final section = (student['year_section'] ?? '').toString();
                  final faName = student['assigned_faculty_name']?.toString() ?? '';
                  final activeOds = (student['active_od_count'] as int?) ?? 0;
                  final totalOds = (student['total_od_count'] as int?) ?? 0;
                  final latestOd = student['latest_od_request'] as Map<String, dynamic>?;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppInitialsAvatar(
                              name: name,
                              size: 44,
                              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                              foregroundColor: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          regNo,
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$program • $section',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (faName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.verified_user_outlined, size: 12, color: Colors.teal),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            'Faculty Advisor: $faName',
                                            style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.history_rounded, size: 15),
                              label: Text(isDesktop ? 'View OD History' : 'Records', style: const TextStyle(fontSize: 11.5)),
                              onPressed: () => _inspectStudentRecords(student),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (latestOd != null) ...[
                              if (latestOd['is_evidence_overdue'] == true) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red.shade700),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Overdue Proof (${latestOd['days_past_event'] ?? 1}d)',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                constraints: const BoxConstraints(maxWidth: 280),
                                decoration: BoxDecoration(
                                  color: _getStatusBadgeColor(latestOd['status'] ?? '').withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _getStatusBadgeColor(latestOd['status'] ?? '').withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 12, color: _getStatusBadgeColor(latestOd['status'] ?? '')),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        'Latest: ${latestOd['reason'] ?? "OD"} (${_formatStatusLabel(latestOd['status'] ?? '')})',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusBadgeColor(latestOd['status'] ?? ''),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (activeOds > 0)
                              _Badge(label: '$activeOds Active', color: Colors.orange.shade900, bg: Colors.orange.shade50),
                            _Badge(label: '$totalOds Lifetime', color: Colors.grey.shade700, bg: Colors.grey.shade100),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
