import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/authentication.dart';
import '../widgets/command_palette_dialog.dart';
import 'admin_dashboard_view.dart';
import 'user_management_view.dart';
import 'department_management_view.dart';
import 'faculty_management_view.dart';
import 'student_registry_view.dart';
import 'organization_settings_view.dart';
import 'audit_logs_view.dart';
import 'system_monitoring_view.dart';
import 'security_center_view.dart';
import 'admin_analytics_view.dart';

class AdminControlCenterShell extends ConsumerStatefulWidget {
  const AdminControlCenterShell({super.key});

  @override
  ConsumerState<AdminControlCenterShell> createState() => _AdminControlCenterShellState();
}

class _AdminControlCenterShellState extends ConsumerState<AdminControlCenterShell> {
  int _activeModuleIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Map<String, dynamic>> _sidebarNavItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard},
    {'title': 'Users & Access', 'icon': Icons.people_alt_outlined, 'activeIcon': Icons.people_alt},
    {'title': 'Departments', 'icon': Icons.account_tree_outlined, 'activeIcon': Icons.account_tree},
    {'title': 'Faculty Workload', 'icon': Icons.badge_outlined, 'activeIcon': Icons.badge},
    {'title': 'Student Registry', 'icon': Icons.school_outlined, 'activeIcon': Icons.school},
    {'title': 'Org Settings', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings},
    {'title': 'Audit Logs', 'icon': Icons.history_outlined, 'activeIcon': Icons.history},
    {'title': 'Monitoring', 'icon': Icons.monitor_heart_outlined, 'activeIcon': Icons.monitor_heart},
    {'title': 'Security Center', 'icon': Icons.security_outlined, 'activeIcon': Icons.security},
    {'title': 'Analytics & PDF', 'icon': Icons.analytics_outlined, 'activeIcon': Icons.analytics},
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final adminName = session?.name ?? 'Master Admin';
    final isMobile = MediaQuery.of(context).size.width < 900;

    final List<Widget> views = [
      AdminDashboardView(onNavigateToModule: (idx) => setState(() => _activeModuleIndex = idx)),
      const UserManagementView(),
      const DepartmentManagementView(),
      const FacultyManagementView(),
      const StudentRegistryView(),
      const OrganizationSettingsView(),
      const AuditLogsView(),
      const SystemMonitoringView(),
      const SecurityCenterView(),
      const AdminAnalyticsView(),
    ];

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A365D),
          foregroundColor: Colors.white,
          elevation: 1,
          title: Text(
            _sidebarNavItems[_activeModuleIndex]['title'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CommandPaletteDialog(
                    onSelectView: (idx) => setState(() => _activeModuleIndex = idx),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: _buildSidebarContent(adminName: adminName, isDrawer: true),
        ),
        body: IndexedStack(
          index: _activeModuleIndex,
          children: views,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Row(
        children: [
          // Collapsible Desktop Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarCollapsed ? 72 : 240,
            child: _buildSidebarContent(adminName: adminName, isDrawer: false),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      // Module Title / Breadcrumb
                      Text(
                        _sidebarNavItems[_activeModuleIndex]['title'] as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                      ),
                      const Spacer(),

                      // Command Palette Button (Ctrl+K)
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => CommandPaletteDialog(
                              onSelectView: (idx) => setState(() => _activeModuleIndex = idx),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, size: 18, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Search platform or modules... (Ctrl+K)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // User Admin Badge
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF1A365D),
                            radius: 16,
                            child: Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(adminName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const Text('MASTER ADMIN', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active View Stack
                Expanded(
                  child: IndexedStack(
                    index: _activeModuleIndex,
                    children: views,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent({required String adminName, required bool isDrawer}) {
    final collapsed = !isDrawer && _isSidebarCollapsed;

    return Container(
      color: const Color(0xFF1A365D),
      child: SafeArea(
        top: isDrawer,
        bottom: true,
        child: Column(
          children: [
            // Header Branding
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Colors.amber, size: 28),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SRM ADMIN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (!isDrawer)
                    IconButton(
                      icon: Icon(_isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.white70),
                      onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),

            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _sidebarNavItems.length,
                itemBuilder: (context, index) {
                  final item = _sidebarNavItems[index];
                  final isSelected = index == _activeModuleIndex;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.white.withValues(alpha: 0.15),
                    leading: Icon(
                      isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                      color: isSelected ? Colors.amber : Colors.white70,
                    ),
                    title: collapsed
                        ? null
                        : Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                    onTap: () {
                      setState(() => _activeModuleIndex = index);
                      if (isDrawer) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),

            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: collapsed ? null : const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}
