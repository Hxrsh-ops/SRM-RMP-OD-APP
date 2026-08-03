import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';
import 'app_brand_logo.dart';
import 'app_initials_avatar.dart';

class AppDesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String role;
  final String userName;
  final VoidCallback? onLogout;

  const AppDesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.role = 'STUDENT',
    this.userName = 'User',
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = role == 'STUDENT';
    final isFaculty = role == 'FACULTY_ADVISOR';

    final roleLabel = isStudent
        ? 'Student'
        : (isFaculty ? 'Faculty Advisor' : 'Coordinator');

    return Container(
      width: 260,
      color: AppColors.primaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SRM RMP Header Logo
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AppBrandLogo(size: 40, showWordmark: true, isDarkBackground: true),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Navigation Links List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Overview',
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
                _SidebarItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: isStudent ? 'My Requests' : (isFaculty ? 'Pending Reviews' : 'Approval Queue'),
                  isSelected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                if (isStudent)
                  _SidebarItem(
                    icon: Icons.add_circle_outline_rounded,
                    activeIcon: Icons.add_circle_rounded,
                    label: 'Create OD Request',
                    isSelected: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                _SidebarItem(
                  icon: Icons.notifications_none_rounded,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Notifications',
                  isSelected: selectedIndex == (isStudent ? 3 : 2),
                  onTap: () => onDestinationSelected(isStudent ? 3 : 2),
                ),
                _SidebarItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == (isStudent ? 4 : 3),
                  onTap: () => onDestinationSelected(isStudent ? 4 : 3),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // Bottom Profile Initials Card & Logout Button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderMd,
              ),
              child: Row(
                children: [
                  AppInitialsAvatar(
                    name: userName,
                    size: 38,
                    backgroundColor: AppColors.accentYellow,
                    foregroundColor: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onLogout != null)
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                      onPressed: onLogout,
                      tooltip: 'Logout',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? AppColors.primaryLight : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.white70;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.borderMd,
            ),
            child: Row(
              children: [
                Icon(isSelected ? activeIcon : icon, color: textColor, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
