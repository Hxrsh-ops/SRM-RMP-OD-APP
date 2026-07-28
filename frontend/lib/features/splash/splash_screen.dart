import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/tokens/theme_tokens.dart';
import '../../core/ui/layout/app_brand_logo.dart';
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Session restoration happens via authControllerProvider
    await ref.read(authControllerProvider.notifier).restoreSession();

    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.session != null) {
      context.go('/dashboard');
    } else {
      context.go(AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Spacer(),
            // Campus Graphic Footer Placeholder
            Opacity(
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
