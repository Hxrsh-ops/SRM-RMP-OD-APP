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
  final bool forcePasswordChange;
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
    this.forcePasswordChange = false,
    required this.token,
  });

  UserSession copyWith({
    String? userId,
    String? username,
    String? name,
    String? email,
    String? role,
    String? program,
    String? yearSection,
    String? assignedFacultyName,
    bool? forcePasswordChange,
    AuthToken? token,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      program: program ?? this.program,
      yearSection: yearSection ?? this.yearSection,
      assignedFacultyName: assignedFacultyName ?? this.assignedFacultyName,
      forcePasswordChange: forcePasswordChange ?? this.forcePasswordChange,
      token: token ?? this.token,
    );
  }

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
        forcePasswordChange,
        token,
      ];
}
