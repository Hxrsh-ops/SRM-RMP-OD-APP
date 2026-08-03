import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import '../../../od_workflow/presentation/controllers/workflow_controller.dart';
import '../../../od_workflow/presentation/views/create_od_request_view.dart';
import '../views/coordinator_dashboard_view.dart';
import '../views/faculty_dashboard_view.dart';
import '../views/my_requests_view.dart';
import '../views/notifications_view.dart';
import '../views/profile_view.dart';
import '../views/student_dashboard_view.dart';

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
    final isStudent = role == 'STUDENT';
    final userName = session?.name ?? 'User';
    final userSubtext = session?.program ?? session?.role ?? 'SRM Ramapuram';

    final unreadCount = workflowState.notifications.where((n) => !n.isRead).length;

    final List<Widget> pages = isStudent
        ? [
            const _HomeDashboardView(),
            const MyRequestsView(),
            _CreateOdRequestFlowView(
              onSuccess: () => setState(() => _currentIndex = 1),
            ),
            const NotificationsView(),
            const ProfileView(),
          ]
        : const [
            _HomeDashboardView(),
            _AllRequestsView(),
            NotificationsView(),
            ProfileView(),
          ];

    final safeIndex = _currentIndex < pages.length ? _currentIndex : 0;
    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
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
                    onNotificationTap: () {
                      setState(() => _currentIndex = isStudent ? 3 : 2);
                    },
                    onProfileTap: () {
                      setState(() => _currentIndex = isStudent ? 4 : 3);
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
    }

    return Scaffold(
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
        preferredSize: const Size.fromHeight(64.0),
        child: AppTopHeader(
          userName: userName,
          userSubtext: userSubtext,
          unreadNotificationCount: unreadCount,
          onNotificationTap: () {
            setState(() => _currentIndex = isStudent ? 3 : 2);
          },
          onProfileTap: () {
            setState(() => _currentIndex = isStudent ? 4 : 3);
          },
          onMenuTap: ResponsiveLayout.isTablet(context)
              ? () => _scaffoldKey.currentState?.openDrawer()
              : null,
        ),
      ),
      body: SafeArea(
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
}

// -----------------------------------------------------------------------------
// HOME DASHBOARD DELEGATOR VIEW
// -----------------------------------------------------------------------------
class _HomeDashboardView extends ConsumerWidget {
  const _HomeDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((s) => s.session?.role ?? 'STUDENT'));

    if (role == 'FACULTY_ADVISOR') {
      return const FacultyDashboardView();
    } else if (role == 'COORDINATOR') {
      return const CoordinatorDashboardView();
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
    } else if (role == 'COORDINATOR') {
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
