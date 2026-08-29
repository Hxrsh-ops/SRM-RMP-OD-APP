import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_service.dart';

class FlutterSecureStorageService implements SecureStorageService {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Fallback try without encryptedSharedPreferences if keystore issue occurs
      try {
        const fallbackStorage = FlutterSecureStorage();
        await fallbackStorage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      try {
        const fallbackStorage = FlutterSecureStorage();
        return await fallbackStorage.read(key: key);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
