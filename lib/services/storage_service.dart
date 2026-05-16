import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keySheetId = 'sheet_id';
  static const _keyActiveUser = 'active_user';
  static const _defaultSheetId = '143As1yj2VM1r5zAbFHphzulltAchpySKCmPINWKV_f0';

  static Future<String> getSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySheetId) ?? _defaultSheetId;
  }

  static Future<void> setSheetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySheetId, id.trim());
  }

  static Future<String?> getActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveUser);
  }

  static Future<void> setActiveUser(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveUser, name);
  }

  static Future<void> clearActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveUser);
  }
}
