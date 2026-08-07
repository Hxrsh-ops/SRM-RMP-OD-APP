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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Registry & Access Control', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Manage Students, Faculty Advisors, Coordinators, HODs, Deans & Administrators', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  if (_selectedUserIds.isNotEmpty) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.block, color: Colors.orange),
                      label: Text('Deactivate (${_selectedUserIds.length})'),
                      onPressed: () => _performBulkAction('deactivate'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      label: Text('Activate (${_selectedUserIds.length})'),
                      onPressed: () => _performBulkAction('activate'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.person_add),
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
                              ref.refresh(adminUsersProvider);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User account created successfully')));
                              }
                            } catch (e) {
                              if (mounted) {
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, email, or register number...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        ref.read(userQueryParamsProvider.notifier).state = params.copyWith(query: val, page: 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: params.role,
                    hint: const Text('All Roles'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Roles')),
                      DropdownMenuItem(value: 'STUDENT', child: Text('Students')),
                      DropdownMenuItem(value: 'FACULTY_ADVISOR', child: Text('Faculty Advisors')),
                      DropdownMenuItem(value: 'COORDINATOR', child: Text('Coordinators')),
                      DropdownMenuItem(value: 'MASTER_ADMIN', child: Text('Master Admins')),
                    ],
                    onChanged: (val) {
                      ref.read(userQueryParamsProvider.notifier).state = params.copyWith(role: val, page: 1);
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh),
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
                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (val) {
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
                                    DataCell(Text(u.isLocked ? 'Locked' : 'Normal', style: TextStyle(color: u.isLocked ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
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
                                                  ref.refresh(adminUsersProvider);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(u.isActive ? Icons.toggle_on : Icons.toggle_off, color: u.isActive ? Colors.green : Colors.grey),
                                          onPressed: () async {
                                            final repo = ref.read(adminRepositoryProvider);
                                            await repo.updateUserStatus(u.id, isActive: !u.isActive);
                                            ref.refresh(adminUsersProvider);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.lock_reset, size: 18, color: Colors.indigo),
                                          onPressed: () => _promptResetPassword(u),
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
      ref.refresh(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bulk $action completed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
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
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully')));
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
