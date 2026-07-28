import 'package:equatable/equatable.dart';
import 'auth_token.dart';

class UserSession extends Equatable {
  final String userId;
  final String username;
  final String name;
  final String email;
  final String role;
  final String? program;
  final String? yearSection;
  final String? assignedFacultyName;
  final AuthToken token;

  const UserSession({
    required this.userId,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    this.program,
    this.yearSection,
    this.assignedFacultyName,
    required this.token,
  });

  @override
  List<Object?> get props => [
        userId,
        username,
        name,
        email,
        role,
        program,
        yearSection,
        assignedFacultyName,
        token,
      ];
}
