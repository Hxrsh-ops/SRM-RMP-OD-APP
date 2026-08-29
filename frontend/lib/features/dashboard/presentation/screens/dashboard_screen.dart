import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/ui/command_palette_dialog.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/views/create_od_request_view.dart';
import '../views/coordinator_dashboard_view.dart';
import '../views/coordinator_overview_view.dart';
import '../views/department_student_directory_view.dart';
import '../views/faculty_advisees_view.dart';
import '../views/faculty_dashboard_view.dart';
import '../views/faculty_overview_view.dart';
import '../views/my_requests_view.dart';
import '../views/notifications_view.dart';
import '../views/profile_view.dart';
import '../views/student_dashboard_view.dart';

import '../../../admin/presentation/views/admin_control_center_shell.dart';

class MainShellDashboardScreen extends ConsumerStatefulWidget {
  const MainShellDashboardScreen({super.key});

  @override
  ConsumerState<MainShellDashboardScreen> createState() => _MainShellDashboardScreenState();
}

class _MainShellDashboardScreenState extends ConsumerState<MainShellDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final workflowState = ref.watch(workflowControllerProvider);

    final role = session?.role ?? 'STUDENT';

    if (role == 'MASTER_ADMIN') {
      return const AdminControlCenterShell();
    }
    final isStudent = role == 'STUDENT';
    final isFaculty = role == 'FACULTY_ADVISOR';
    final userName = session?.name ?? 'User';
    final userSubtext = session?.program ?? session?.role ?? 'SRM Ramapuram';

    final unreadCount = workflowState.notifications.where((n) => !n.isRead).length;

    final List<Widget> pages = isStudent
        ? [
            const StudentDashboardView(),
            const MyRequestsView(),
            _CreateOdRequestFlowView(
              onSuccess: () => setState(() => _currentIndex = 1),
            ),
            const NotificationsView(),
            const ProfileView(),
          ]
        : (isFaculty
            ? [
                _HomeDashboardView(
                  onNavigateToQueue: () => setState(() => _currentIndex = 1),
                ),
                const _AllRequestsView(),
                const FacultyAdviseesView(),
                const NotificationsView(),
                const ProfileView(),
              ]
            : [
                _HomeDashboardView(
                  onNavigateToQueue: () => setState(() => _currentIndex = 1),
                ),
                const _AllRequestsView(),
                const DepartmentStudentDirectoryView(),
                const NotificationsView(),
                const ProfileView(),
              ]);

    final safeIndex = _currentIndex < pages.length ? _currentIndex : 0;
    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);
    final topInset = isDesktop ? 0.0 : MediaQuery.paddingOf(context).top;

    void openCommandPalette() {
      CommandPaletteDialog.show(context, onNavigate: (idx) => setState(() => _currentIndex = idx));
    }

    Widget content;
    if (isDesktop) {
      content = Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            AppDesktopSidebar(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              role: role,
              userName: userName,
              onLogout: () {
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
            Expanded(
              child: Column(
                children: [
                  AppTopHeader(
                    userName: userName,
                    userSubtext: userSubtext,
                    unreadNotificationCount: unreadCount,
                    onSearchTap: openCommandPalette,
                    onNotificationTap: () {
                      setState(() => _currentIndex = 3);
                    },
                    onProfileTap: () {
                      setState(() => _currentIndex = 4);
                    },
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: safeIndex,
                      children: pages,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      content = Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: ResponsiveLayout.isTablet(context)
            ? Drawer(
                child: AppDesktopSidebar(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                    Navigator.pop(context);
                  },
                  role: role,
                  userName: userName,
                  onLogout: () {
                    Navigator.pop(context);
                    ref.read(authControllerProvider.notifier).logout();
                  },
                ),
              )
            : null,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(64.0 + topInset),
          child: AppTopHeader(
            userName: userName,
            userSubtext: userSubtext,
            unreadNotificationCount: unreadCount,
            onSearchTap: openCommandPalette,
            onNotificationTap: () {
              setState(() => _currentIndex = 3);
            },
            onProfileTap: () {
              setState(() => _currentIndex = 4);
            },
            onMenuTap: ResponsiveLayout.isTablet(context)
                ? () => _scaffoldKey.currentState?.openDrawer()
                : null,
          ),
        ),
        body: SafeArea(
          top: false,
          child: IndexedStack(
            index: safeIndex,
            children: pages,
          ),
        ),
        bottomNavigationBar: ResponsiveLayout.isMobile(context)
            ? AppBottomNavBar(
                currentIndex: safeIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                role: role,
              )
            : null,
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): openCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: content,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HOME DASHBOARD DELEGATOR VIEW
// -----------------------------------------------------------------------------
class _HomeDashboardView extends ConsumerWidget {
  final VoidCallback? onNavigateToQueue;

  const _HomeDashboardView({this.onNavigateToQueue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((s) => s.session?.role ?? 'STUDENT'));

    if (role == 'FACULTY_ADVISOR') {
      return FacultyOverviewView(onNavigateToQueue: onNavigateToQueue);
    } else if (role == 'COORDINATOR' || role == 'HOD' || role == 'DEAN') {
      return CoordinatorOverviewView(onNavigateToQueue: onNavigateToQueue);
    }

    return const StudentDashboardView();
  }
}

// -----------------------------------------------------------------------------
// ALL REQUESTS DELEGATOR VIEW
// -----------------------------------------------------------------------------
class _AllRequestsView extends ConsumerWidget {
  const _AllRequestsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((s) => s.session?.role ?? 'STUDENT'));

    if (role == 'FACULTY_ADVISOR') {
      return const FacultyDashboardView();
    } else if (role == 'COORDINATOR' || role == 'HOD' || role == 'DEAN') {
      return const CoordinatorDashboardView();
    }

    return const MyRequestsView();
  }
}

// -----------------------------------------------------------------------------
// CREATE OD REQUEST FLOW VIEW
// -----------------------------------------------------------------------------
class _CreateOdRequestFlowView extends ConsumerWidget {
  final VoidCallback? onSuccess;

  const _CreateOdRequestFlowView({this.onSuccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CreateOdRequestView(onSuccess: onSuccess);
  }
}
