import 'package:flutter/material.dart';
import '../../domain/models/admin_models.dart';

class UserFormDialog extends StatefulWidget {
  final AdminUser? user;
  final List<AdminDepartment> departments;
  final List<ClassSectionModel> classSections;
  final Future<void> Function(Map<String, dynamic> formData) onSubmit;

  const UserFormDialog({
    super.key,
    this.user,
    required this.departments,
    this.classSections = const [],
    required this.onSubmit,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _passwordController;
  late TextEditingController _customSectionController;

  String _role = 'STUDENT';
  String? _departmentId;
  int? _selectedAcademicYear;
  String? _selectedClassSectionId;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _fullNameController = TextEditingController(text: widget.user?.fullName ?? '');
    _passwordController = TextEditingController();
    _customSectionController = TextEditingController();
    _role = widget.user?.role ?? 'STUDENT';
    _departmentId = widget.user?.departmentId ?? (widget.departments.isNotEmpty ? widget.departments.first.id : null);

    if (widget.user != null) {
      if (widget.user!.classSectionId != null) {
        final sec = widget.classSections.where((s) => s.id == widget.user!.classSectionId).firstOrNull;
        if (sec != null) {
          _selectedAcademicYear = sec.academicYear;
          _selectedClassSectionId = sec.id;
        }
      } else if (widget.user!.yearSection != null) {
        final ys = widget.user!.yearSection!;
        if (ys.contains('1')) {
          _selectedAcademicYear = 1;
        } else if (ys.contains('2')) {
          _selectedAcademicYear = 2;
        } else if (ys.contains('3')) {
          _selectedAcademicYear = 3;
        } else if (ys.contains('4')) {
          _selectedAcademicYear = 4;
        }
        
        final parts = ys.split('-');
        if (parts.length > 1) {
          _customSectionController.text = parts[1].trim();
        }
      }
    } else {
      _selectedAcademicYear = 1;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _customSectionController.dispose();
    super.dispose();
  }

  AdminDepartment? get _currentDepartment {
    return widget.departments.where((d) => d.id == _departmentId).firstOrNull;
  }

  List<ClassSectionModel> get _availableSectionsForYear {
    return widget.classSections.where((s) =>
        s.departmentId == _departmentId &&
        (_selectedAcademicYear == null || s.academicYear == _selectedAcademicYear)
    ).toList();
  }

  ClassSectionModel? get _selectedSectionModel {
    if (_selectedClassSectionId == null) return null;
    return widget.classSections.where((s) => s.id == _selectedClassSectionId).firstOrNull;
  }

  String _getResolvedProgram() {
    final sec = _selectedSectionModel;
    if (sec != null && sec.program != null && sec.program!.isNotEmpty) {
      return sec.program!;
    }
    final dept = _currentDepartment;
    if (dept != null) {
      return 'B.Tech ${dept.name}';
    }
    return 'B.Tech Computer Science & Engineering';
  }

  String _getResolvedYearSection() {
    final year = _selectedAcademicYear ?? 1;
    final sec = _selectedSectionModel;
    final secName = sec != null ? sec.section : (_customSectionController.text.trim().isNotEmpty ? _customSectionController.text.trim() : 'Sec A');
    return '$year${_getOrdinal(year)} Year - $secName';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final availableSections = _availableSectionsForYear;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Edit User Record' : 'Provision New Account',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                ),
                const SizedBox(height: 16),
                if (_errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _usernameController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Username / Register No / Employee ID',
                    hintText: 'e.g. RA2511026020400 or FA1002 or ADMIN1001',
                    border: const OutlineInputBorder(),
                    helperText: isEdit ? 'Username can be updated for this account' : null,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. K M HARSHANTH',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Institutional Email Address',
                    hintText: 'e.g. hk7793@srmist.edu.in',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid institutional email required' : null,
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isSubmitting,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Initial Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                ],
                const SizedBox(height: 12),
                if (widget.user?.role == 'MASTER_ADMIN') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A365D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1A365D).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF1A365D), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role: Master Admin (System Superuser)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A365D)),
                              ),
                              Text(
                                'Role is permanent and locked for security. Username and personal info can be changed above.',
                                style: TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Role & Privilege Tier',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'STUDENT', child: Text('Student', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'FACULTY_ADVISOR', child: Text('Faculty Advisor', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'COORDINATOR', child: Text('Department Coordinator', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'HOD', child: Text('Head of Department (HOD)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'DEAN', child: Text('Dean (Campus Authority)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'MASTER_ADMIN', child: Text('Master Admin (System Superuser)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: _isSubmitting ? null : (val) {
                      if (val != null) {
                        setState(() {
                          _role = val;
                          if (val == 'DEAN' || val == 'MASTER_ADMIN') {
                            _departmentId = null;
                          } else if (_departmentId == null && widget.departments.isNotEmpty) {
                            _departmentId = widget.departments.first.id;
                          }
                        });
                      }
                    },
                  ),
                ],
                if (_role != 'DEAN' && _role != 'MASTER_ADMIN') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _departmentId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Department',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.departments.map((d) {
                      return DropdownMenuItem(
                        value: d.id,
                        child: Text('${d.name} (${d.code})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _isSubmitting ? null : (val) {
                      setState(() {
                        _departmentId = val;
                        _selectedClassSectionId = null;
                      });
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.account_balance, color: Color(0xFF1A365D), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Institutional / Campus-Wide Authority (No department restriction)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A365D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_role == 'STUDENT') ...[
                  const SizedBox(height: 14),
                  // Step 1: Academic Year Selector
                  DropdownButtonFormField<int>(
                    initialValue: _selectedAcademicYear,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1st Year (Semester 1 & 2)')),
                      DropdownMenuItem(value: 2, child: Text('2nd Year (Semester 3 & 4)')),
                      DropdownMenuItem(value: 3, child: Text('3rd Year (Semester 5 & 6)')),
                      DropdownMenuItem(value: 4, child: Text('4th Year (Semester 7 & 8)')),
                    ],
                    onChanged: _isSubmitting ? null : (val) {
                      setState(() {
                        _selectedAcademicYear = val;
                        _selectedClassSectionId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Step 2: Class Section Selector (strictly filtered to selected year & dept)
                  if (availableSections.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedClassSectionId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Class Section for ${_selectedAcademicYear != null ? "$_selectedAcademicYear${_getOrdinal(_selectedAcademicYear!)} Year" : "Department"}',
                        prefixIcon: const Icon(Icons.class_outlined, size: 20),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Custom Section Entry...', style: TextStyle(color: Colors.grey)),
                        ),
                        ...availableSections.map((sec) {
                          final faInfo = sec.facultyAdvisorName != null ? '• FA: ${sec.facultyAdvisorName}' : '• FA: Unassigned';
                          return DropdownMenuItem<String?>(
                            value: sec.id,
                            child: Text('${sec.section} ($faInfo)', overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: _isSubmitting ? null : (val) {
                        setState(() {
                          _selectedClassSectionId = val;
                        });
                      },
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _customSectionController,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Section Name for ${_selectedAcademicYear ?? 1}${_getOrdinal(_selectedAcademicYear ?? 1)} Year',
                        hintText: 'e.g. Sec A, Sec B, Sec G',
                        prefixIcon: const Icon(Icons.class_outlined, size: 20),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  if (_selectedClassSectionId == null && availableSections.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customSectionController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Custom Section Name',
                        hintText: 'e.g. Sec A',
                        prefixIcon: Icon(Icons.edit_note_outlined, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Auto-Populated Student Profile Preview Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A365D).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1A365D).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: Color(0xFF1A365D)),
                            SizedBox(width: 6),
                            Text(
                              'Auto-Generated Academic Information',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Text('Academic Program: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Expanded(
                              child: Text(
                                _getResolvedProgram(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A365D)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Year & Section: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Expanded(
                              child: Text(
                                _getResolvedYearSection(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A365D)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Faculty Advisor: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Expanded(
                              child: Text(
                                _selectedSectionModel?.facultyAdvisorName != null
                                    ? '${_selectedSectionModel!.facultyAdvisorName!} (${_selectedSectionModel!.facultyAdvisorEmail ?? ""})'
                                    : 'Will be assigned based on section in Department setup',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedSectionModel?.facultyAdvisorName != null ? Colors.green.shade800 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A365D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isSubmitting = true;
                                  _errorText = null;
                                });
                                try {
                                  final data = <String, dynamic>{
                                    'username': _usernameController.text.trim(),
                                    'full_name': _fullNameController.text.trim(),
                                    'email': _emailController.text.trim(),
                                    'role': _role,
                                    'department_id': _departmentId,
                                    if (_role == 'STUDENT') ...{
                                      if (_selectedClassSectionId != null) 'class_section_id': _selectedClassSectionId,
                                      'program': _getResolvedProgram(),
                                      'year_section': _getResolvedYearSection(),
                                    }
                                  };
                                  if (!isEdit) {
                                    data['password'] = _passwordController.text;
                                  }
                                  await widget.onSubmit(data);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      _errorText = e.toString().replaceAll('Exception:', '').trim();
                                    });
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSubmitting = false);
                                  }
                                }
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Save Changes' : 'Create User'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getOrdinal(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}
