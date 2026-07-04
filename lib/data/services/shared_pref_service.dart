import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkle_lite/core/utils/logger.dart';

class SharedPreferencesService {
  SharedPreferencesService._();
  static final SharedPreferencesService instance = SharedPreferencesService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    Logger.info('SharedPreferencesService → initialized');
  }

  SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'SharedPreferencesService.init() must be called before use (call it in main() before runApp).',
      );
    }
    return prefs;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _instance.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    await _instance.setBool(key, value);
  }

  String? getString(String key) => _instance.getString(key);

  Future<void> setString(String key, String value) async {
    await _instance.setString(key, value);
  }

  Future<void> remove(String key) async {
    await _instance.remove(key);
  }

  Future<void> clearAll() async {
    await _instance.clear();
  }
}
