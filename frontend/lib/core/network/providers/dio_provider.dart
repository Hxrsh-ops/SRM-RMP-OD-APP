import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../security/flutter_secure_storage_service.dart';
import '../../security/secure_storage_service.dart';
import '../api_client.dart';
import '../api_constants.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/error_interceptor.dart';
import '../interceptors/logging_interceptor.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return FlutterSecureStorageService();
});

final useApiRepositoryProvider = StateProvider<bool>((ref) => true);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  // Auto detect desktop vs mobile base URL
  final String base = kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux
      ? ApiConstants.desktopBaseUrl
      : ApiConstants.baseUrl;

  final options = BaseOptions(
    baseUrl: base,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);

  dio.interceptors.addAll([
    AuthInterceptor(storage),
    LoggingInterceptor(),
    ErrorInterceptor(),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
