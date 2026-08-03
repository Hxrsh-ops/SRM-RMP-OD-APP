import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/authentication.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../constants/app_constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    refreshListenable: _ListenableAdapter(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final status = authState.status;

      final isSplashLocation = state.matchedLocation == AppConstants.splashRoute;
      final isLoginLocation = state.matchedLocation == AppConstants.loginRoute;

      // 1. While initial/restoring, keep user on Splash
      if (status == AuthStatus.initial) {
        return isSplashLocation ? null : AppConstants.splashRoute;
      }

      // 2. If authenticated, redirect away from Splash & Login to Dashboard
      if (status == AuthStatus.authenticated) {
        if (isSplashLocation || isLoginLocation) {
          return '/dashboard';
        }
        return null;
      }

      // 3. For unauthenticated, failure, sessionExpired: redirect away from Splash & protected routes to Login
      if (isSplashLocation || !isLoginLocation) {
        return AppConstants.loginRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        builder: (context, state) => const AuthSplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainShellDashboardScreen(),
      ),
    ],
  );
});

class _ListenableAdapter extends ChangeNotifier {
  _ListenableAdapter(Ref ref) {
    ref.listen(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
}
