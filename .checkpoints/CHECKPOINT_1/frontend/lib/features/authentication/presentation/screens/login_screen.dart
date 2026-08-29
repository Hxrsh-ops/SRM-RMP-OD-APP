import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/tokens/theme_tokens.dart';
import '../../../../core/ui/ui.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isLaptop(context) || ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop ? AppColors.surfaceVariant : AppColors.primaryBlue,
      body: isDesktop
          ? Row(
              children: [
                // Left Branding Panel (40% width)
                Expanded(
                  flex: 4,
                  child: Container(
                    color: AppColors.primaryBlue,
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppBrandLogo(size: 80, showWordmark: false, isDarkBackground: true),
                        const SizedBox(height: AppSpacing.xl),
                        const Text(
                          'SRM RMP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'ON DUTY WORKFLOW PLATFORM',
                          style: TextStyle(
                            color: AppColors.accentYellow,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'SRM INSTITUTE OF SCIENCE & TECHNOLOGY',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Empowering Students, Enabling Excellence.',
                                style: TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Login Form Panel (60% width)
                Expanded(
                  flex: 6,
                  child: Container(
                    color: AppColors.surface,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Welcome Back',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Sign in to continue',
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              const LoginForm(),
                              const SizedBox(height: AppSpacing.xxxl),
                              const Center(
                                child: Text(
                                  '© 2026 SRM Institute of Science & Technology. All rights reserved.',
                                  style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          // Mobile / Tablet Stacked Layout
          : SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      width: double.infinity,
                      color: AppColors.primaryBlue,
                      child: const Column(
                        children: [
                          AppBrandLogo(size: 56, showWordmark: false, isDarkBackground: true),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'SRM RMP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'ON DUTY PLATFORM',
                            style: TextStyle(
                              color: AppColors.accentYellow,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Sign in to continue',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          const LoginForm(),
                          const SizedBox(height: AppSpacing.xl),
                          const Center(
                            child: Text(
                              '© 2026 SRM Institute of Science & Technology. All rights reserved.',
                              style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
