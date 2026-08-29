import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String role;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'STUDENT',
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = role == 'STUDENT';
    final isFaculty = role == 'FACULTY_ADVISOR';

    final List<BottomNavigationBarItem> items = isStudent
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'My Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ]
        : (isFaculty
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment_rounded),
                  label: 'Pending',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline_rounded),
                  activeIcon: Icon(Icons.people_rounded),
                  label: 'Advisees',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_none_rounded),
                  activeIcon: Icon(Icons.notifications_rounded),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment_rounded),
                  label: 'Approval Queue',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.badge_outlined),
                  activeIcon: Icon(Icons.badge_rounded),
                  label: 'Directory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_none_rounded),
                  activeIcon: Icon(Icons.notifications_rounded),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ]);

    final safeIndex = currentIndex < items.length ? currentIndex : 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: items,
      ),
    );
  }
}
