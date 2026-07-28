import '../../domain/entities/user_session.dart';
import 'auth_token_model.dart';

class UserSessionModel extends UserSession {
  const UserSessionModel({
    required super.userId,
    required super.username,
    required super.name,
    required super.email,
    required super.role,
    required AuthTokenModel super.token,
  });

  factory UserSessionModel.fromJson(Map<String, dynamic> json) {
    return UserSessionModel(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      token: AuthTokenModel.fromJson(json['token'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'token': (token as AuthTokenModel).toJson(),
    };
  }

  factory UserSessionModel.fromEntity(UserSession entity) {
    return UserSessionModel(
      userId: entity.userId,
      username: entity.username,
      name: entity.name,
      email: entity.email,
      role: entity.role,
      token: AuthTokenModel.fromEntity(entity.token),
    );
  }
}
