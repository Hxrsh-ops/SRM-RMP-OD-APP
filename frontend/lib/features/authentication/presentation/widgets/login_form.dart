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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.status == AuthStatus.failure && authState.errorMessage != null) ...[
            AppStatusChip(
              label: authState.errorMessage!,
              statusType: AppStatusType.error,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Register Number / Username Input Field
          AppTextField(
            controller: _usernameController,
            labelText: 'Register Number',
            hintText: 'RA2111003010001',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            enabled: !isAuthenticating,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your Register Number';
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
              Row(
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
                  Text(
                    'Remember me',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AppTextButton(
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
          const SizedBox(height: AppSpacing.lg),

          // Don't have an account? Register Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registration is managed by SRM IT Cell.')),
                  );
                },
                child: Text(
                  'Register',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
