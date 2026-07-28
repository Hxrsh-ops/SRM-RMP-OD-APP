import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../services/logging_service.dart';

class DioClient {
  late final Dio _dio;

  DioClient(EnvConfig config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Attach Interceptors
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _AuthInterceptorPlaceholder(),
      _RetryInterceptorPlaceholder(),
    ]);
  }

  Dio get instance => _dio;
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LoggingService.debug('HTTP GET/POST Request: ${options.method} ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LoggingService.debug('HTTP Response [${response.statusCode}]: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LoggingService.error('HTTP Request Error: ${err.message}', err);
    super.onError(err, handler);
  }
}

class _AuthInterceptorPlaceholder extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Authentication header injection placeholder (to be populated in future milestone)
    super.onRequest(options, handler);
  }
}

class _RetryInterceptorPlaceholder extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Network retry logic placeholder (to be populated in future milestone)
    super.onError(err, handler);
  }
}
