import 'package:flutter/material.dart';
import '../../domain/models/admin_models.dart';

class UserFormDialog extends StatefulWidget {
  final AdminUser? user;
  final List<AdminDepartment> departments;
  final Function(Map<String, dynamic> formData) onSubmit;

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
                TextFormField(
                  controller: _usernameController,
                  enabled: !isEdit,
                  decoration: const InputDecoration(
                    labelText: 'Username / Register No / Employee ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
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
                  decoration: const InputDecoration(
                    labelText: 'Role & Privilege Tier',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                    DropdownMenuItem(value: 'FACULTY_ADVISOR', child: Text('Faculty Advisor')),
                    DropdownMenuItem(value: 'COORDINATOR', child: Text('Coordinator')),
                    DropdownMenuItem(value: 'HOD', child: Text('Head of Department (HOD)')),
                    DropdownMenuItem(value: 'DEAN', child: Text('Dean')),
                    DropdownMenuItem(value: 'MASTER_ADMIN', child: Text('Master Admin (Full Authority)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _role = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _departmentId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Department',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.departments.map((d) {
                    return DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.code})'));
                  }).toList(),
                  onChanged: (val) => setState(() => _departmentId = val),
                ),
                if (_role == 'STUDENT') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _programController,
                    decoration: const InputDecoration(
                      labelText: 'Academic Program (e.g. B.Tech CSE AI&ML)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _yearSectionController,
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A365D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
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
                          widget.onSubmit(data);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(isEdit ? 'Save Changes' : 'Create User'),
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
