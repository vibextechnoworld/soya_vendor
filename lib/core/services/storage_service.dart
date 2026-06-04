import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _themeKey = 'theme_mode';
  static const _rememberKey = 'remember';
  static const _firstuserKey = 'firstuser';

  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  static Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  static Future<void> saveRemember(String remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberKey, remember);
  }

  static Future<String?> getRemember() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberKey);
  }

  static Future<void> saveFirstuser(String firstuser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_firstuserKey, firstuser);
  }

  static Future<String?> getFirstuser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firstuserKey);
  }

  static Future<void> save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
