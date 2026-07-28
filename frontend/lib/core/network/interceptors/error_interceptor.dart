import 'package:dio/dio.dart';
import '../exceptions/api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiException;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      apiException = const NetworkException();
    } else if (err.response != null) {
      final statusCode = err.response?.statusCode;
      final data = err.response?.data;
      String message = 'API Error ($statusCode)';

      if (data is Map && data.containsKey('detail')) {
        message = data['detail'].toString();
      }

      switch (statusCode) {
        case 401:
          apiException = UnauthorizedException(message: message, data: data);
          break;
        case 403:
          apiException = ForbiddenException(message: message, data: data);
          break;
        case 404:
          apiException = NotFoundApiException(message: message, data: data);
          break;
        case 500:
        default:
          apiException = ServerException(message: message, statusCode: statusCode, data: data);
          break;
      }
    } else {
      apiException = ApiException(message: err.message ?? 'An unexpected network error occurred.');
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
        type: err.type,
        response: err.response,
      ),
    );
  }
}
