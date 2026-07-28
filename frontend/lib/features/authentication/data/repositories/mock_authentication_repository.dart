import '../../domain/entities/user_session.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/auth_token_model.dart';
import '../models/user_session_model.dart';

class MockAuthenticationRepository implements AuthenticationRepository {
  final AuthLocalDataSource _localDataSource;

  MockAuthenticationRepository(this._localDataSource);

  @override
  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));

    final token = AuthTokenModel(
      accessToken: 'mock_jwt_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_jwt_refresh_token',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    final session = UserSessionModel(
      userId: 'usr_mock_1001',
      username: username,
      name: 'SRM Student User',
      email: '$username@srmist.edu.in',
      role: 'STUDENT',
      token: token,
    );

    await _localDataSource.saveSession(session);
    return session;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _localDataSource.clearSession();
  }

  @override
  Future<UserSession?> restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return await _localDataSource.getSession();
  }

  @override
  Future<bool> isAuthenticated() async {
    final session = await _localDataSource.getSession();
    return session != null;
  }
}
