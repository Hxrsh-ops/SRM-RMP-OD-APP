import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers/dio_provider.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/api_authentication_repository.dart';
import '../../data/repositories/mock_authentication_repository.dart';
import '../../domain/entities/auth_status.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import 'auth_state.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthLocalDataSource(storage);
});

final authenticationRepositoryProvider = Provider<AuthenticationRepository>((ref) {
  final useApi = ref.watch(useApiRepositoryProvider);
  if (useApi) {
    final apiClient = ref.watch(apiClientProvider);
    final storage = ref.watch(secureStorageProvider);
    return ApiAuthenticationRepository(apiClient: apiClient, storageService: storage);
  } else {
    final localDataSource = ref.watch(authLocalDataSourceProvider);
    return MockAuthenticationRepository(localDataSource: localDataSource);
  }
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authenticationRepositoryProvider);
  return LoginUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authenticationRepositoryProvider);
  return LogoutUseCase(repository);
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  final repository = ref.watch(authenticationRepositoryProvider);
  return RestoreSessionUseCase(repository);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    restoreSessionUseCase: ref.watch(restoreSessionUseCaseProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;

  AuthController({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _restoreSessionUseCase = restoreSessionUseCase,
        super(const AuthState());

  void toggleRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);

    try {
      final session = await _loginUseCase.execute(
        username: username,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceFirst('AppException: ', '').replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final session = await _restoreSessionUseCase.execute();
      if (session != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
