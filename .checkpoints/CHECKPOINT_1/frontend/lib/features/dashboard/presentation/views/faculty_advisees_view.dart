import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';

class FacultyAdviseesView extends ConsumerStatefulWidget {
  const FacultyAdviseesView({super.key});

  @override
  ConsumerState<FacultyAdviseesView> createState() => _FacultyAdviseesViewState();
}

class _FacultyAdviseesViewState extends ConsumerState<FacultyAdviseesView> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _advisees = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAdvisees();
  }

  Future<void> _fetchAdvisees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(workflowRepositoryProvider);
      final list = await repo.getFacultyAdvisees();
      if (mounted) {
        setState(() {
          _advisees = list;
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

  void _inspectAdviseeRecords(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (ctx) => AdviseeRecordsInspectionDialog(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);
    final session = ref.watch(authControllerProvider).session;

    final filtered = _advisees.where((st) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;
      final name = (st['full_name'] ?? '').toString().toLowerCase();
      final reg = (st['username'] ?? '').toString().toLowerCase();
      final prog = (st['program'] ?? '').toString().toLowerCase();
      final sec = (st['year_section'] ?? '').toString().toLowerCase();
      return name.contains(query) || reg.contains(query) || prog.contains(query) || sec.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchAdvisees,
        child: ListView(
          padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.md),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Advisees Directory',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mentorship roster & historical OD records inspection for ${session?.name ?? "Faculty Advisor"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _fetchAdvisees,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Roster',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    icon: Icons.people_alt_outlined,
                    color: AppColors.primaryBlue,
                    label: 'Total Advisees',
                    value: '${_advisees.length}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricPill(
                    icon: Icons.assignment_late_outlined,
                    color: Colors.orange.shade800,
                    label: 'Active ODs',
                    value: '${_advisees.fold<int>(0, (sum, st) => sum + ((st["active_od_count"] as int?) ?? 0))}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricPill(
                    icon: Icons.history_edu_outlined,
                    color: Colors.green.shade700,
                    label: 'Lifetime Submissions',
                    value: '${_advisees.fold<int>(0, (sum, st) => sum + ((st["total_od_count"] as int?) ?? 0))}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search advisees by student name, register number, section...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
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
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                      Text('Failed to load advisees: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(onPressed: _fetchAdvisees, child: const Text('Try Again')),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      Icon(Icons.person_search_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _searchQuery.isEmpty ? 'No students assigned to your mentorship roster yet.' : 'No advisees matching "$_searchQuery"',
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
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final student = filtered[index];
                  final name = (student['full_name'] ?? 'Student').toString();
                  final regNo = (student['username'] ?? '').toString();
                  final program = (student['program'] ?? '').toString();
                  final section = (student['year_section'] ?? '').toString();
                  final cgpa = (student['cgpa'] ?? '8.5').toString();
                  final attendance = (student['attendance_percentage'] ?? '88.0').toString();
                  final activeOds = (student['active_od_count'] as int?) ?? 0;
                  final totalOds = (student['total_od_count'] as int?) ?? 0;

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
                    child: Row(
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      regNo,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$program • $section',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _Badge(label: 'CGPA $cgpa', color: Colors.blue.shade700, bg: Colors.blue.shade50),
                                  _Badge(label: 'Attd $attendance%', color: Colors.teal.shade700, bg: Colors.teal.shade50),
                                  if (activeOds > 0)
                                    _Badge(label: '$activeOds Active OD(s)', color: Colors.orange.shade900, bg: Colors.orange.shade50),
                                  _Badge(label: '$totalOds Total Submission(s)', color: Colors.grey.shade700, bg: Colors.grey.shade100),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.history_rounded, size: 16),
                          label: Text(isDesktop ? 'View OD History' : 'Records', style: const TextStyle(fontSize: 12)),
                          onPressed: () => _inspectAdviseeRecords(student),
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

class AdviseeRecordsInspectionDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> student;
  const AdviseeRecordsInspectionDialog({super.key, required this.student});

  @override
  ConsumerState<AdviseeRecordsInspectionDialog> createState() => _AdviseeRecordsInspectionDialogState();
}

class _AdviseeRecordsInspectionDialogState extends ConsumerState<AdviseeRecordsInspectionDialog> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(workflowRepositoryProvider);
      final data = await repo.getAdviseeRecords(widget.student['id'].toString());
      if (mounted) {
        setState(() {
          _records = (data['records'] as List?) ?? [];
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

  String _formatStatusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'PENDING_FACULTY':
        return 'Pending Faculty Review';
      case 'FACULTY_APPROVED':
        return 'Faculty Approved';
      case 'PENDING_COORDINATOR':
        return 'Pending Dept Approval';
      case 'APPROVED_AWAITING_EVIDENCE':
        return 'Approved • Awaiting Evidence';
      case 'PENDING_EVIDENCE_FACULTY':
        return 'Proof Review (Faculty)';
      case 'PENDING_EVIDENCE_COORDINATOR':
        return 'Proof Review (Dept)';
      case 'COMPLETED':
        return 'Completed & Granted';
      case 'REJECTED':
      case 'FACULTY_REJECTED':
        return 'Rejected';
      case 'REVISION_REQUESTED':
      case 'EVIDENCE_REVISION_REQUESTED':
        return 'Revision Requested';
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
    final name = (widget.student['full_name'] ?? 'Student').toString();
    final regNo = (widget.student['username'] ?? '').toString();
    final program = (widget.student['program'] ?? '').toString();
    final section = (widget.student['year_section'] ?? '').toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppInitialsAvatar(
                  name: name,
                  size: 40,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        '$regNo • $program ($section)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _fetchRecords,
                  tooltip: 'Refresh Records',
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Associated OD Submissions (${_records.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text(
                  'Read-Only Mentorship Inspection',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                      : _records.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No OD records submitted by this student yet.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _records.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final r = _records[i] as Map<String, dynamic>;
                                final reqId = (r['id'] ?? 'OD-REQ').toString();
                                final reason = (r['reason'] ?? 'Event').toString();
                                final purpose = (r['purpose'] ?? '').toString();
                                final startDate = (r['start_date'] ?? '').toString();
                                final endDate = (r['end_date'] ?? '').toString();
                                final durationDays = (r['duration_days'] ?? '1').toString();
                                final statusRaw = (r['status'] ?? 'PENDING').toString();
                                final statusBadgeColor = _getStatusBadgeColor(statusRaw);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                reqId,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '$durationDays Day(s)',
                                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusBadgeColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _formatStatusLabel(statusRaw),
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusBadgeColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Event: $reason ($startDate to $endDate)',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      if (purpose.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Purpose: $purpose',
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
