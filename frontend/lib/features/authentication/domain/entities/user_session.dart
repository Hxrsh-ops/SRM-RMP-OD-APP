import 'package:equatable/equatable.dart';
import 'auth_token.dart';

class UserSession extends Equatable {
  final String userId;
  final String username;
  final String name;
  final String email;
  final String role;
  final AuthToken token;

  const UserSession({
    required this.userId,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, username, name, email, role, token];
}
