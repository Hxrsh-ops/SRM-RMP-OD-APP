import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/authentication_repository.dart';

class ApiAuthenticationRepository implements AuthenticationRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  ApiAuthenticationRepository({
    required this.apiClient,
    required this.storageService,
  });

  @override
  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
        'remember_me': true,
      },
    );

    final accessToken = response['access_token'] as String;
    final refreshToken = response['refresh_token'] as String;
    final userData = response['user'] as Map<String, dynamic>;

    await storageService.write(key: ApiConstants.tokenKey, value: accessToken);
    await storageService.write(key: ApiConstants.refreshTokenKey, value: refreshToken);

    final session = UserSession(
      userId: userData['id'].toString(),
      username: userData['username'].toString(),
      name: userData['full_name'].toString(),
      email: userData['email'].toString(),
      role: userData['role'].toString(),
      token: AuthToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      ),
    );

    return session;
  }

  @override
  Future<UserSession?> restoreSession() async {
    final token = await storageService.read(key: ApiConstants.tokenKey);
    final refreshToken = await storageService.read(key: ApiConstants.refreshTokenKey) ?? '';
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final userData = await apiClient.get(ApiConstants.me);
      return UserSession(
        userId: userData['id'].toString(),
        username: userData['username'].toString(),
        name: userData['full_name'].toString(),
        email: userData['email'].toString(),
        role: userData['role'].toString(),
        token: AuthToken(
          accessToken: token,
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      );
    } catch (_) {
      await logout();
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final session = await restoreSession();
    return session != null;
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.logout);
    } catch (_) {}
    await storageService.delete(key: ApiConstants.tokenKey);
    await storageService.delete(key: ApiConstants.refreshTokenKey);
  }
}
