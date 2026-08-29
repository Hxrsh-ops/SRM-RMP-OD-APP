import '../repositories/authentication_repository.dart';

class LogoutUseCase {
  final AuthenticationRepository _repository;

  const LogoutUseCase(this._repository);

  Future<void> execute() async {
    await _repository.logout();
  }
}
