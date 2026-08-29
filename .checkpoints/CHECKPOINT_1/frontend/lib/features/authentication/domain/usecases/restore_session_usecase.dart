import '../entities/user_session.dart';
import '../repositories/authentication_repository.dart';

class RestoreSessionUseCase {
  final AuthenticationRepository _repository;

  const RestoreSessionUseCase(this._repository);

  Future<UserSession?> execute() async {
    return await _repository.restoreSession();
  }
}
