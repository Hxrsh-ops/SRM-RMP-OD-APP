import '../entities/user_session.dart';

abstract class AuthenticationRepository {
  Future<UserSession> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<UserSession?> restoreSession();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<bool> isAuthenticated();
}
