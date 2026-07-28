import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/authentication.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../constants/app_constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authControllerProvider.notifier);

  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    refreshListenable: _ListenableAdapter(authNotifier),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthenticating = authState.status == AuthStatus.authenticating;

      final isSplashLocation = state.matchedLocation == AppConstants.splashRoute;
      final isLoginLocation = state.matchedLocation == AppConstants.loginRoute;

      // Allow splash to perform startup session restoration
      if (isSplashLocation && isAuthenticating) {
        return null;
      }

      // If authenticated, redirect away from public login/splash to protected dashboard
      if (isAuth) {
        if (isLoginLocation || isSplashLocation) {
          return '/dashboard';
        }
        return null;
      }

      // If unauthenticated and trying to access protected routes, redirect to login
      if (!isAuth && !isLoginLocation && !isSplashLocation) {
        return AppConstants.loginRoute;
      }

      // Default redirect from splash to login if session check finishes unauthenticated
      if (isSplashLocation && !isAuthenticating && !isAuth) {
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
  _ListenableAdapter(StateNotifier notifier) {
    notifier.addListener((_) {
      notifyListeners();
    });
  }
}
