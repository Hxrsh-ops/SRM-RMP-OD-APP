import '../../../../core/utils/errors.dart';
import '../entities/user_session.dart';
import '../repositories/authentication_repository.dart';

class LoginUseCase {
  final AuthenticationRepository _repository;

  const LoginUseCase(this._repository);

  Future<UserSession> execute({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty) {
      throw const ValidationException(message: 'Username/Register Number cannot be empty.');
    }

    if (cleanPassword.isEmpty) {
      throw const ValidationException(message: 'Password cannot be empty.');
    }

    if (cleanPassword.length < 6) {
      throw const ValidationException(message: 'Password must be at least 6 characters.');
    }

    return await _repository.login(
      username: cleanUsername,
      password: cleanPassword,
    );
  }
}
