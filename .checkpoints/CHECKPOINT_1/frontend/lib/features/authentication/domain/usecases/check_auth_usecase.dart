import '../repositories/authentication_repository.dart';

class CheckAuthUseCase {
  final AuthenticationRepository _repository;

  const CheckAuthUseCase(this._repository);

  Future<bool> execute() async {
    return await _repository.isAuthenticated();
  }
}
