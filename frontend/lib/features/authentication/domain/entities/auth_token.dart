import 'package:equatable/equatable.dart';

class AuthToken extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}
