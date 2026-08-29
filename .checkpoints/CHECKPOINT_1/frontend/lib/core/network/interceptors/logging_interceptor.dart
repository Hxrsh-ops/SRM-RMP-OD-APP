import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint('[API REQUEST] ${options.method} -> ${options.uri}');
      if (options.data != null) {
        debugPrint('[API DATA] ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['request_start_time'] as int?;
    final durationMs = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : 0;
    if (kDebugMode) {
      debugPrint('[API RESPONSE] ${response.statusCode} <- ${response.requestOptions.method} ${response.requestOptions.uri} ($durationMs ms)');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['request_start_time'] as int?;
    final durationMs = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : 0;
    if (kDebugMode) {
      debugPrint('[API ERROR] ${err.response?.statusCode} <- ${err.requestOptions.method} ${err.requestOptions.uri} ($durationMs ms) | Message: ${err.message}');
    }
    handler.next(err);
  }
}
