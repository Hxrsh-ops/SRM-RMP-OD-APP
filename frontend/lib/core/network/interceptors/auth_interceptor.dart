import 'package:dio/dio.dart';
import '../../security/secure_storage_service.dart';
import '../api_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;

  AuthInterceptor(this.storageService);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storageService.read(key: ApiConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
