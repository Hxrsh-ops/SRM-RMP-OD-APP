import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../widgets/user_form_dialog.dart';
import '../../domain/models/admin_models.dart';

class UserManagementView extends ConsumerStatefulWidget {
  const UserManagementView({super.key});

  @override
  ConsumerState<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends ConsumerState<UserManagementView> {
  final _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final deptsAsync = ref.watch(adminDepartmentsProvider);
    final params = ref.watch(userQueryParamsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Action Bar
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Registry & Access Control', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Manage Students, Faculty Advisors, Coordinators, HODs, Deans & Administrators', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedUserIds.isNotEmpty) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.block, color: Colors.orange, size: 18),
                      label: Text('Deactivate (${_selectedUserIds.length})'),
                      onPressed: () => _performBulkAction('deactivate'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                      label: Text('Activate (${_selectedUserIds.length})'),
                      onPressed: () => _performBulkAction('activate'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: Text('Delete (${_selectedUserIds.length})'),
                      onPressed: () => _promptBulkDelete(),
                    ),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Provision User'),
                    onPressed: () {
                      final depts = deptsAsync.value ?? [];
                      showDialog(
                        context: context,
                        builder: (_) => UserFormDialog(
                          departments: depts,
                          onSubmit: (formData) async {
                            try {
                              final repo = ref.read(adminRepositoryProvider);
                              await repo.createUser(formData);
                              ref.invalidate(adminUsersProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User account created successfully')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters Row
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 200, maxWidth: 350),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, email, or reg no...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        ref.read(userQueryParamsProvider.notifier).state = params.copyWith(query: val, page: 1);
                      },
                    ),
                  ),
                  DropdownButton<String>(
                    value: params.role,
                    hint: const Text('All Roles'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Roles')),
                      DropdownMenuItem(value: 'STUDENT', child: Text('Students')),
                      DropdownMenuItem(value: 'FACULTY_ADVISOR', child: Text('Faculty Advisors')),
                      DropdownMenuItem(value: 'COORDINATOR', child: Text('Coordinators')),
                      DropdownMenuItem(value: 'HOD', child: Text('HODs')),
                      DropdownMenuItem(value: 'DEAN', child: Text('Deans')),
                      DropdownMenuItem(value: 'MASTER_ADMIN', child: Text('Master Admins')),
                    ],
                    onChanged: (val) {
                      ref.read(userQueryParamsProvider.notifier).state = params.copyWith(role: val, page: 1, clearRole: val == null);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Users',
                    onPressed: () => ref.refresh(adminUsersProvider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Users Table
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading users: $err')),
              data: (data) {
                final List<AdminUser> items = data['items'];
                final int totalPages = data['total_pages'];

                if (items.isEmpty) {
                  return const Center(child: Text('No users match current filters'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('User')),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Department')),
                                DataColumn(label: Text('Program / Sec')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Security')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: items.map((u) {
                                final isSelected = _selectedUserIds.contains(u.id);
                                final isAdmin = u.role == 'MASTER_ADMIN';
                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: isAdmin
                                      ? null
                                      : (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedUserIds.add(u.id);
                                            } else {
                                              _selectedUserIds.remove(u.id);
                                            }
                                          });
                                        },
                                  cells: [
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${u.username} • ${u.email}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    )),
                                    DataCell(_buildRoleBadge(u.role)),
                                    DataCell(Text(u.departmentName ?? 'Unassigned')),
                                    DataCell(Text(u.program != null ? '${u.program} (${u.yearSection ?? ''})' : '-')),
                                    DataCell(_buildStatusChip(u.isActive)),
                                    DataCell(
                                      u.isLocked
                                          ? InkWell(
                                              onTap: () => _promptUnlockUser(u),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.red),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.lock, size: 13, color: Colors.red),
                                                    SizedBox(width: 4),
                                                    Text('Locked (Unlock)', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle_outline, size: 13, color: Colors.green),
                                                  SizedBox(width: 4),
                                                  Text('Normal', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                    ),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.folder_shared_outlined, size: 18, color: Color(0xFF1A365D)),
                                          tooltip: 'View Profile & OD Records',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => UserRecordsDialog(user: u),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          tooltip: 'Edit User',
                                          onPressed: () {
                                            final depts = deptsAsync.value ?? [];
                                            showDialog(
                                              context: context,
                                              builder: (_) => UserFormDialog(
                                                user: u,
                                                departments: depts,
                                                onSubmit: (formData) async {
                                                  final repo = ref.read(adminRepositoryProvider);
                                                  await repo.updateUser(u.id, formData);
                                                  ref.invalidate(adminUsersProvider);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        if (isAdmin)
                                          const Tooltip(
                                            message: 'Master Admin is permanently active',
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.toggle_on, color: Colors.grey, size: 22),
                                            ),
                                          )
                                        else
                                          IconButton(
                                            icon: Icon(
                                              u.isActive ? Icons.toggle_on : Icons.toggle_off,
                                              color: u.isActive ? Colors.green : Colors.grey,
                                            ),
                                            tooltip: u.isActive ? 'Deactivate User' : 'Activate User',
                                            onPressed: () async {
                                              try {
                                                final repo = ref.read(adminRepositoryProvider);
                                                await repo.updateUserStatus(u.id, isActive: !u.isActive);
                                                ref.invalidate(adminUsersProvider);
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Failed to update user status: $e'), backgroundColor: Colors.red),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        if (u.isLocked)
                                          IconButton(
                                            icon: const Icon(Icons.lock_open, size: 18, color: Colors.orange),
                                            tooltip: 'Unlock Account',
                                            onPressed: () => _promptUnlockUser(u),
                                          ),
                                        if (u.role == 'STUDENT')
                                          IconButton(
                                            icon: const Icon(Icons.person_add_alt_1, size: 18, color: Colors.teal),
                                            tooltip: 'Assign Faculty Advisor',
                                            onPressed: () => _promptAssignAdvisor(u),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.lock_reset, size: 18, color: Colors.indigo),
                                          tooltip: 'Reset Password',
                                          onPressed: () => _promptResetPassword(u),
                                        ),
                                        if (!isAdmin)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            tooltip: 'Delete User',
                                            onPressed: () => _promptDeleteUser(u),
                                          )
                                        else
                                          const Tooltip(
                                            message: 'Master Admin account cannot be deleted',
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.lock, size: 16, color: Colors.grey),
                                            ),
                                          ),
                                      ],
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Showing ${items.length} of ${data['total']} users'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: params.page > 1
                                  ? () {
                                      ref.read(userQueryParamsProvider.notifier).state = params.copyWith(page: params.page - 1);
                                    }
                                  : null,
                            ),
                            Text('Page ${params.page} of $totalPages'),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: params.page < totalPages
                                  ? () {
                                      ref.read(userQueryParamsProvider.notifier).state = params.copyWith(page: params.page + 1);
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'MASTER_ADMIN':
        color = Colors.purple;
        break;
      case 'COORDINATOR':
        color = Colors.indigo;
        break;
      case 'FACULTY_ADVISOR':
        color = Colors.teal;
        break;
      default:
        color = Colors.blue;
    }
    return Chip(
      label: Text(role, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Chip(
      label: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: isActive ? Colors.green[800] : Colors.red[800])),
      backgroundColor: isActive ? Colors.green[50] : Colors.red[50],
      visualDensity: VisualDensity.compact,
    );
  }

  void _performBulkAction(String action) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.bulkUserAction(_selectedUserIds.toList(), action);
      setState(() => _selectedUserIds.clear());
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bulk $action completed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _promptBulkDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedUserIds.length} Selected Users'),
        content: Text('Are you sure you want to permanently soft-delete these ${_selectedUserIds.length} user accounts? This action will disable their access in PostgreSQL.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _performBulkAction('delete');
            },
            child: const Text('Delete Selected'),
          ),
        ],
      ),
    );
  }

  void _promptUnlockUser(AdminUser u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlock Account: ${u.fullName}'),
        content: Text('Do you want to unlock user ${u.username} (${u.email})? This will reset failed login attempts to 0 and restore full account access immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            icon: const Icon(Icons.lock_open, size: 16),
            label: const Text('Unlock Account'),
            onPressed: () async {
              try {
                final repo = ref.read(adminRepositoryProvider);
                await repo.updateUserStatus(u.id, isLocked: false);
                ref.invalidate(adminUsersProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Account for ${u.fullName} unlocked successfully.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to unlock user: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _promptResetPassword(AdminUser u) {
    final pwdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for ${u.fullName}'),
        content: TextField(
          controller: pwdController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (pwdController.text.length >= 6) {
                final repo = ref.read(adminRepositoryProvider);
                await repo.resetPassword(u.id, pwdController.text);
                ref.invalidate(adminUsersProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password reset successfully')));
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _promptDeleteUser(AdminUser u) {
    if (u.role == 'MASTER_ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The sole active MASTER_ADMIN account cannot be deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete User Account: ${u.fullName}'),
        content: Text('Are you sure you want to permanently soft-delete user ${u.username} (${u.email})? This action will disable their access in PostgreSQL.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final repo = ref.read(adminRepositoryProvider);
                await repo.deleteUser(u.id);
                ref.invalidate(adminUsersProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('User ${u.username} deleted successfully')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete User'),
          ),
        ],
      ),
    );
  }

  void _promptAssignAdvisor(AdminUser student) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final availableFaculty = await repo.getAvailableFaculty(student.id);
      if (!mounted) return;
      if (availableFaculty.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active Faculty Advisors found in this department.'), backgroundColor: Colors.orange),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (_) => _AssignAdvisorDialog(
          student: student,
          facultyList: availableFaculty,
          onAssign: (facultyId) async {
            await repo.assignFaculty(student.id, facultyId);
            ref.invalidate(adminUsersProvider);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading faculty list: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _AssignAdvisorDialog extends StatefulWidget {
  final AdminUser student;
  final List<AdminUser> facultyList;
  final Future<void> Function(String facultyId) onAssign;

  const _AssignAdvisorDialog({
    required this.student,
    required this.facultyList,
    required this.onAssign,
  });

  @override
  State<_AssignAdvisorDialog> createState() => _AssignAdvisorDialogState();
}

class _AssignAdvisorDialogState extends State<_AssignAdvisorDialog> {
  String? _selectedFacultyId;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedFacultyId = widget.student.assignedFacultyId ?? (widget.facultyList.isNotEmpty ? widget.facultyList.first.id : null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Advisor: ${widget.student.fullName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Register No: ${widget.student.username}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            if (_errorText != null) ...[
              Text(_errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _selectedFacultyId,
              decoration: const InputDecoration(
                labelText: 'Select Faculty Advisor',
                border: OutlineInputBorder(),
              ),
              items: widget.facultyList.map((f) {
                return DropdownMenuItem(value: f.id, child: Text('${f.fullName} (${f.email})'));
              }).toList(),
              onChanged: _isSubmitting ? null : (val) => setState(() => _selectedFacultyId = val),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A365D), foregroundColor: Colors.white),
                  onPressed: (_isSubmitting || _selectedFacultyId == null)
                      ? null
                      : () async {
                          setState(() {
                            _isSubmitting = true;
                            _errorText = null;
                          });
                          try {
                            await widget.onAssign(_selectedFacultyId!);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) setState(() => _errorText = e.toString().replaceAll('Exception:', '').trim());
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        },
                  child: _isSubmitting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Assign Advisor'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// USER RECORDS & OD REQUEST INSPECTION DIALOG (WITH PERMANENT DELETION)
// -----------------------------------------------------------------------------
class UserRecordsDialog extends ConsumerStatefulWidget {
  final AdminUser user;
  const UserRecordsDialog({super.key, required this.user});

  @override
  ConsumerState<UserRecordsDialog> createState() => _UserRecordsDialogState();
}

class _UserRecordsDialogState extends ConsumerState<UserRecordsDialog> {
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
      final repo = ref.read(adminRepositoryProvider);
      final data = await repo.getUserProfileAndRecords(widget.user.id);
      if (mounted) {
        setState(() {
          _records = data['records'] as List? ?? [];
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

  Future<void> _deleteRecord(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete OD Record?'),
        content: Text('Are you sure you want to permanently delete OD record $requestId? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(adminRepositoryProvider);
        await repo.deleteOdRequest(requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Record $requestId deleted successfully')));
          _fetchRecords();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting record: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1A365D).withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: Color(0xFF1A365D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A365D).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(widget.user.role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A365D))),
                          ),
                        ],
                      ),
                      Text('${widget.user.username} • ${widget.user.email} • ${widget.user.departmentName ?? "No Dept"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Records',
                  onPressed: _fetchRecords,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Associated OD Submissions (${_records.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Text('Master Admin Record Control', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error loading records: $_error', style: const TextStyle(color: Colors.red)))
                      : _records.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No OD records found for this user', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _records.length,
                              itemBuilder: (context, idx) {
                                final r = _records[idx] as Map<String, dynamic>;
                                final reqId = r['id']?.toString() ?? '';
                                final reason = r['reason']?.toString() ?? 'OD Event';
                                final statusStr = r['status']?.toString() ?? '';
                                final duration = r['duration_days'] ?? 1;
                                final startDate = r['start_date']?.toString() ?? '';
                                final endDate = r['end_date']?.toString() ?? '';
                                final purpose = r['purpose']?.toString() ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0.8,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(reqId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A365D))),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text('$duration Day(s)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(statusStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text('Event: $reason ($startDate to $endDate)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                              if (purpose.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text('Purpose: $purpose', style: const TextStyle(fontSize: 11, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                                          tooltip: 'Delete this OD Record',
                                          onPressed: () => _deleteRecord(reqId),
                                        ),
                                      ],
                                    ),
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
