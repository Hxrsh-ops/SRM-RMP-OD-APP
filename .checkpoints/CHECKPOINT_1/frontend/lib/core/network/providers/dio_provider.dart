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

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final baseUrl = ApiConstants.baseUrl;

  if (kDebugMode) {
    debugPrint('[SRM RMP OD Network Initialization] Resolved API Base URL: $baseUrl');
  }

  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);

  dio.interceptors.addAll([
    AuthInterceptor(storage, dio),
    LoggingInterceptor(),
    ErrorInterceptor(),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
