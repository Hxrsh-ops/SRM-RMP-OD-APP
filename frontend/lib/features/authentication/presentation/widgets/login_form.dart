import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../../domain/entities/auth_status.dart';
import '../controllers/auth_controller.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'RA2510026020400');
  final _passwordController = TextEditingController(text: 'student123');

  int _selectedRoleIndex = 0; // 0: Student, 1: Faculty Advisor, 2: Coordinator

  void _onRoleChanged(int index) {
    setState(() {
      _selectedRoleIndex = index;
      if (index == 0) {
        _usernameController.text = 'RA2510026020400';
        _passwordController.text = 'student123';
      } else if (index == 1) {
        _usernameController.text = 'FA1001';
        _passwordController.text = 'faculty123';
      } else {
        _usernameController.text = 'CO1001';
        _passwordController.text = 'coord123';
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).login(
            username: _usernameController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isAuthenticating = authState.status == AuthStatus.authenticating;

    final String labelText = _selectedRoleIndex == 0 ? 'Register Number' : 'Employee ID';
    final String hintText = _selectedRoleIndex == 0 ? 'RA2510026020400' : (_selectedRoleIndex == 1 ? 'FA1001' : 'CO1001');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Role Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.borderMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RoleSegmentButton(
                    label: 'Student',
                    isSelected: _selectedRoleIndex == 0,
                    onTap: () => _onRoleChanged(0),
                  ),
                ),
                Expanded(
                  child: _RoleSegmentButton(
                    label: 'Faculty',
                    isSelected: _selectedRoleIndex == 1,
                    onTap: () => _onRoleChanged(1),
                  ),
                ),
                Expanded(
                  child: _RoleSegmentButton(
                    label: 'Coordinator',
                    isSelected: _selectedRoleIndex == 2,
                    onTap: () => _onRoleChanged(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (authState.status == AuthStatus.failure && authState.errorMessage != null) ...[
            AppStatusChip(
              label: authState.errorMessage!,
              statusType: AppStatusType.error,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Username / Register Number / Employee ID Field
          AppTextField(
            controller: _usernameController,
            labelText: labelText,
            hintText: hintText,
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            enabled: !isAuthenticating,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your $labelText';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Password Field
          AppPasswordField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: '••••••••',
            enabled: !isAuthenticating,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your password';
              }
              if (value.trim().length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Remember Me & Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: authState.rememberMe,
                        activeColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: isAuthenticating
                            ? null
                            : (val) => ref
                                .read(authControllerProvider.notifier)
                                .toggleRememberMe(val ?? false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Remember me',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: AppTextButton(
                  label: 'Forgot Password?',
                  size: AppButtonSize.small,
                  onPressed: isAuthenticating
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset placeholder. Contact HOD/Admin.'),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Sign In Submit Button
          AppPrimaryButton(
            label: 'Sign In',
            isLoading: isAuthenticating,
            size: AppButtonSize.large,
            onPressed: isAuthenticating ? null : _onLoginPressed,
          ),
        ],
      ),
    );
  }
}

class _RoleSegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: AppRadius.borderMd,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
