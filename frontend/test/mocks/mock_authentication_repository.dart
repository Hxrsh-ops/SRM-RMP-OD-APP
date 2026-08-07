import 'package:srm_rmp_od_frontend/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/models/auth_token_model.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/models/user_session_model.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/entities/user_session.dart';
import 'package:srm_rmp_od_frontend/features/authentication/domain/repositories/authentication_repository.dart';

class MockAuthenticationRepository implements AuthenticationRepository {
  final AuthLocalDataSource localDataSource;

  MockAuthenticationRepository({required this.localDataSource});

  @override
  Future<UserSession> login({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));

    final trimmedUsername = username.trim();
    final trimmedPassword = password.trim();

    String role = 'STUDENT';
    String name = 'K.M. Harshanth';
    String email = 'hk7793@srmist.edu.in';

    if (trimmedUsername == 'RA2510026020400' && trimmedPassword == 'student123') {
      role = 'STUDENT';
      name = 'K.M. Harshanth';
      email = 'hk7793@srmist.edu.in';
    } else if (trimmedUsername == 'FA1001' && trimmedPassword == 'faculty123') {
      role = 'FACULTY_ADVISOR';
      name = 'Dr. Karthik B (Mock)';
      email = 'karthikb@srmist.edu.in';
    } else if (trimmedUsername == 'CO1001' && trimmedPassword == 'coord123') {
      role = 'COORDINATOR';
      name = 'Prof. Ramesh Kumar (Coordinator)';
      email = 'rameshk@srmist.edu.in';
    } else if (trimmedPassword.length < 6) {
      throw Exception('Invalid password. Minimum 6 characters required.');
    } else {
      name = 'User $trimmedUsername';
      email = '$trimmedUsername@srmist.edu.in';
    }

    final tokenModel = AuthTokenModel(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    final sessionModel = UserSessionModel(
      userId: 'usr_$trimmedUsername',
      username: trimmedUsername,
      email: email,
      name: name,
      role: role,
      token: tokenModel,
    );

    if (rememberMe) {
      await localDataSource.saveSession(sessionModel);
    }

    return sessionModel;
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }

  @override
  Future<UserSession?> restoreSession() async {
    final sessionModel = await localDataSource.getSession();
    return sessionModel;
  }

  @override
  Future<bool> isAuthenticated() async {
    final session = await restoreSession();
    return session != null && !session.token.isExpired;
  }
}
