import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    LoggingService.info('Initializing StorageService with SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clear() async {
    return await _prefs.clear();
  }
}
