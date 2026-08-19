import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../../authentication/authentication.dart';
import 'shared_dashboard_widgets.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final userName = session?.name ?? 'User';
    final userRole = session?.role ?? 'STUDENT';
    final isStudent = userRole == 'STUDENT';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Manage institutional account parameters and identity credentials',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // User Card Banner
          AppCard(
            child: Row(
              children: [
                AppInitialsAvatar(
                  name: userName,
                  size: 64,
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        session?.email ?? '—',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppStatusChip(
                        label: userRole.replaceAll('_', ' '),
                        statusType: userRole == 'COORDINATOR' ? AppStatusType.info : (userRole == 'FACULTY_ADVISOR' ? AppStatusType.success : AppStatusType.pending),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Academic Identity Details Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Academic & Institutional Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                const SizedBox(height: AppSpacing.md),
                ProfileDetailRow(label: 'Registration / Employee ID', value: session?.username ?? '—'),
                ProfileDetailRow(label: 'Academic Program', value: session?.program ?? '—'),
                ProfileDetailRow(label: 'Year & Section', value: session?.yearSection ?? '—'),
                if (isStudent) ProfileDetailRow(label: 'Assigned Counselor', value: session?.assignedFacultyName ?? 'Unassigned'),
                const ProfileDetailRow(label: 'Department', value: 'SRM IST Department'),
                const ProfileDetailRow(label: 'Campus', value: 'SRM Institute of Science & Technology, Ramapuram'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Identity Debug Info (Only visible in kDebugMode)
          const BuildIdentityCard(),
          const SizedBox(height: AppSpacing.xl),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: AppSecondaryButton(
              label: 'Sign Out of Account',
              prefixIcon: Icons.logout_rounded,
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
