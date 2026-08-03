import 'package:flutter/material.dart';
import '../../responsive/responsive_layout.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';
import 'app_initials_avatar.dart';

class AppTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String userSubtext;
  final int unreadNotificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onMenuTap;

  const AppTopHeader({
    super.key,
    required this.userName,
    required this.userSubtext,
    this.unreadNotificationCount = 0,
    required this.onNotificationTap,
    required this.onProfileTap,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isLaptop(context);
    final topInset = isDesktop ? 0.0 : MediaQuery.paddingOf(context).top;
    final totalHeight = 64.0 + topInset;

    return Container(
      height: totalHeight,
      padding: EdgeInsets.only(
        top: topInset,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: SizedBox(
        height: 64.0,
        child: Row(
          children: [
            if (!isDesktop && onMenuTap != null) ...[
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                onPressed: onMenuTap,
                tooltip: 'Open Navigation Drawer',
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            // App Header Title & Subtitle (No Overlap)
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SRM RMP OD Platform',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'On Duty Approval Workflow',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Search Bar (Desktop / Laptop)
            if (isDesktop) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: const SizedBox(
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search requests, events...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: AppSpacing.md),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],

            // Notification Icon Button with Badge Counter
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                  onPressed: onNotificationTap,
                  tooltip: 'Notifications',
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadNotificationCount > 9 ? '9+' : '$unreadNotificationCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),

            // Profile Initials Avatar Button
            InkWell(
              onTap: onProfileTap,
              borderRadius: AppRadius.borderFull,
              child: AppInitialsAvatar(
                name: userName,
                size: 36,
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
