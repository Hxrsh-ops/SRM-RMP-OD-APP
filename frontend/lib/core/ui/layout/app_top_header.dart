import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../responsive/responsive_layout.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';
import '../command_palette_dialog.dart';
import 'app_initials_avatar.dart';

class AppTopHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;
  final String userSubtext;
  final int unreadNotificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;

  const AppTopHeader({
    super.key,
    required this.userName,
    required this.userSubtext,
    this.unreadNotificationCount = 0,
    required this.onNotificationTap,
    required this.onProfileTap,
    this.onMenuTap,
    this.onSearchTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            // App Header Title & Subtitle
            const Column(
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

            const Spacer(),

            // Spotlight Search Trigger Bar
            InkWell(
              onTap: onSearchTap ?? () => CommandPaletteDialog.show(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    if (isDesktop) ...[
                      const Text(
                        'Search requests, actions...',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text('Ctrl K', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

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

            // User Initials Avatar and Profile Click
            InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  AppInitialsAvatar(name: userName, size: 34),
                  if (isDesktop) ...[
                    const SizedBox(width: AppSpacing.xs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userSubtext,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
