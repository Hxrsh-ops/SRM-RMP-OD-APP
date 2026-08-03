import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_status.dart';
import '../../domain/entities/user_session.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final UserSession? session;
  final String? errorMessage;
  final bool rememberMe;

  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.errorMessage,
    this.rememberMe = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserSession? session,
    String? errorMessage,
    bool? rememberMe,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage, rememberMe];
}
