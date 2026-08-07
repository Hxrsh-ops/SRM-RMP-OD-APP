import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/security/memory_secure_storage.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/datasources/auth_local_datasource.dart';
import '../../mocks/mock_authentication_repository.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/entities/auth_status.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/usecases/login_usecase.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/usecases/restore_session_usecase.dart';
import 'package:srm_rmp_od_frontend/features/authentication/presentation/controllers/auth_controller.dart';

void main() {
  group('AuthController & Use Cases Unit Tests', () {
    late MemorySecureStorage storage;
    late AuthLocalDataSource localDataSource;
    late MockAuthenticationRepository repository;
    late LoginUseCase loginUseCase;
    late LogoutUseCase logoutUseCase;
    late RestoreSessionUseCase restoreSessionUseCase;
    late AuthController controller;

    setUp(() {
      storage = MemorySecureStorage();
      localDataSource = AuthLocalDataSource(storage);
      repository = MockAuthenticationRepository(localDataSource: localDataSource);
      loginUseCase = LoginUseCase(repository);
      logoutUseCase = LogoutUseCase(repository);
      restoreSessionUseCase = RestoreSessionUseCase(repository);
      controller = AuthController(
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
        restoreSessionUseCase: restoreSessionUseCase,
      );
    });

    test('Initial state is initial', () {
      expect(controller.state.status, AuthStatus.initial);
      expect(controller.state.session, isNull);
    });

    test('Login fails for empty fields', () async {
      await controller.login(username: '', password: '123');
      expect(controller.state.status, AuthStatus.failure);
      expect(controller.state.errorMessage, contains('cannot be empty'));
    });

    test('Login fails for short password (< 6 chars)', () async {
      await controller.login(username: 'RA2510026020400', password: '123');
      expect(controller.state.status, AuthStatus.failure);
      expect(controller.state.errorMessage, contains('at least 6 characters'));
    });

    test('Login succeeds for valid non-empty fields and password >= 6 chars', () async {
      await controller.login(username: 'RA2510026020400', password: 'student123');
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.session, isNotNull);
      expect(controller.state.session?.username, 'RA2510026020400');
    });

    test('Logout clears session and updates state to unauthenticated', () async {
      await controller.login(username: 'RA2510026020400', password: 'student123');
      expect(controller.state.status, AuthStatus.authenticated);

      await controller.logout();
      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.session, isNull);
    });
  });
}
