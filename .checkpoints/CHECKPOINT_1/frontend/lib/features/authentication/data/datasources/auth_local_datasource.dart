import 'dart:convert';
import '../../../../core/security/secure_storage_service.dart';
import '../models/user_session_model.dart';

class AuthLocalDataSource {
  final SecureStorageService _storage;
  static const String _sessionKey = 'active_user_session';

  AuthLocalDataSource(this._storage);

  Future<void> saveSession(UserSessionModel session) async {
    final jsonString = jsonEncode(session.toJson());
    await _storage.write(key: _sessionKey, value: jsonString);
  }

  Future<UserSessionModel?> getSession() async {
    final jsonString = await _storage.read(key: _sessionKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserSessionModel.fromJson(jsonMap);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
