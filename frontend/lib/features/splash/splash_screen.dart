import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/tokens/theme_tokens.dart';
import '../../core/ui/layout/app_brand_logo.dart';
import '../authentication/domain/entities/auth_status.dart';
import '../authentication/presentation/controllers/auth_controller.dart';

class AuthSplashScreen extends ConsumerStatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  ConsumerState<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends ConsumerState<AuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSessionRestoration();
    });
  }

  void _triggerSessionRestoration() {
    final status = ref.read(authControllerProvider).status;
    if (status == AuthStatus.initial) {
      ref.read(authControllerProvider.notifier).restoreSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isRestoring = authState.status == AuthStatus.initial;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Centered Brand Badge & Logo
            const Center(
              child: AppBrandLogo(
                size: 72,
                showWordmark: true,
                isDarkBackground: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'ON DUTY WORKFLOW PLATFORM',
              style: TextStyle(
                color: AppColors.accentYellow,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isRestoring) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Initializing Session...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            const Spacer(),
            // Campus Graphic Footer Placeholder
            const Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.account_balance_rounded,
                size: 120,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'SRM Ramapuram Campus',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
