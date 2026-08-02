import 'package:dio/dio.dart';
import '../../security/secure_storage_service.dart';
import '../api_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor(this.storageService, this.dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storageService.read(key: ApiConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestPath = err.requestOptions.path;
      if (requestPath.contains(ApiConstants.login) || requestPath.contains(ApiConstants.refresh)) {
        return handler.next(err);
      }

      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await storageService.read(key: ApiConstants.refreshTokenKey);
          if (refreshToken != null && refreshToken.isNotEmpty) {
            final refreshResponse = await dio.post(
              ApiConstants.refresh,
              data: {'refresh_token': refreshToken},
              options: Options(headers: {'Authorization': ''}),
            );

            if (refreshResponse.statusCode == 200) {
              final newAccessToken = refreshResponse.data['access_token'] as String;
              final newRefreshToken = refreshResponse.data['refresh_token'] as String;

              await storageService.write(key: ApiConstants.tokenKey, value: newAccessToken);
              await storageService.write(key: ApiConstants.refreshTokenKey, value: newRefreshToken);

              _isRefreshing = false;

              // Retry original failed request with new access token
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(opts);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          _isRefreshing = false;
          await storageService.delete(key: ApiConstants.tokenKey);
          await storageService.delete(key: ApiConstants.refreshTokenKey);
        } finally {
          _isRefreshing = false;
        }
      }
    }
    handler.next(err);
  }
}
