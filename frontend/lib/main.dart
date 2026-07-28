import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/services/logging_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';

// Global providers
final envConfigProvider = Provider<EnvConfig>((ref) => EnvConfig.dev());
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in ProviderScope');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggingService.info('Starting ${AppConstants.appName} application...');

  final storageService = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const SrmRmpOdApp(),
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
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
