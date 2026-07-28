import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
    if (kDebugMode) {
      debugPrint('[API RESPONSE] ${response.statusCode} <- ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[API ERROR] ${err.response?.statusCode} <- ${err.requestOptions.uri} | Message: ${err.message}');
    }
    handler.next(err);
  }
}
