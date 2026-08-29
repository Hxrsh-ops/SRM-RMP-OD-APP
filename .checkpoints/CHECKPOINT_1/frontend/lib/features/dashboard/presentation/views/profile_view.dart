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

          // Security & Password Management Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security & Access Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Update your personal login password anytime to secure your account.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: const Text('Change Password'),
                    onPressed: () => _showChangePasswordDialog(context, ref),
                  ),
                ),
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

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Color(0xFF1A365D), size: 24),
                SizedBox(width: AppSpacing.xs),
                Text('Change Account Password'),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != newPwController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A365D),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);
                        final success = await ref.read(authControllerProvider.notifier).changePassword(
                              currentPassword: currentPwController.text.trim(),
                              newPassword: newPwController.text.trim(),
                            );
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          if (success) {
                            Navigator.pop(dialogCtx);
                            AppSnackbar.showSuccess(context, 'Password changed successfully!');
                          } else {
                            AppSnackbar.showError(dialogCtx, 'Incorrect current password or change failed.');
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }
}
