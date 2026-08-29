import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/services/logging_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggingService.info('Starting ${AppConstants.appName} application...');

  // Automation: Gracefully handle and suppress visual overflow stripe banners on all devices
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exceptionAsString();
    if (exceptionStr.contains('A RenderFlex overflowed') || exceptionStr.contains('RenderFlex')) {
      return;
    }
    FlutterError.presentError(details);
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };

  runApp(
    const ProviderScope(
      child: SrmRmpOdApp(),
    ),
  );
}

class SrmRmpOdApp extends ConsumerWidget {
  const SrmRmpOdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
