import 'package:flutter/material.dart';
import '../../domain/models/admin_models.dart';

class UserFormDialog extends StatefulWidget {
  final AdminUser? user;
  final List<AdminDepartment> departments;
  final Future<void> Function(Map<String, dynamic> formData) onSubmit;

  const UserFormDialog({
    super.key,
    this.user,
    required this.departments,
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
  late TextEditingController _programController;
  late TextEditingController _yearSectionController;

  String _role = 'STUDENT';
  String? _departmentId;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _fullNameController = TextEditingController(text: widget.user?.fullName ?? '');
    _passwordController = TextEditingController();
    _programController = TextEditingController(text: widget.user?.program ?? '');
    _yearSectionController = TextEditingController(text: widget.user?.yearSection ?? '');
    _role = widget.user?.role ?? 'STUDENT';
    _departmentId = widget.user?.departmentId ?? (widget.departments.isNotEmpty ? widget.departments.first.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  enabled: !isEdit && !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Username / Register No / Employee ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
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
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
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
                    onChanged: _isSubmitting ? null : (val) => setState(() => _departmentId = val),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _programController,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Academic Program (e.g. B.Tech CSE AI&ML)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _yearSectionController,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Year & Section (e.g. 2nd Year - Sec G)',
                      border: OutlineInputBorder(),
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
                                    'full_name': _fullNameController.text.trim(),
                                    'email': _emailController.text.trim(),
                                    'role': _role,
                                    'department_id': _departmentId,
                                    if (_role == 'STUDENT') ...{
                                      'program': _programController.text.trim(),
                                      'year_section': _yearSectionController.text.trim(),
                                    }
                                  };
                                  if (!isEdit) {
                                    data['username'] = _usernameController.text.trim();
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
}
