import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyConfigSheetId = 'config_sheet_id';
  static const _keyActiveUser = 'active_user';
  static const _keyActiveBookId = 'active_book_id';
  static const _keyActiveBookName = 'active_book_name';

  /// Default Spreadsheet ID untuk GS Konfigurasi (tertanam di APK).
  static const defaultConfigSheetId = '1bD9B9zw14dOlYurqgbcryDOKjpvqfDwMWxe5MfoXU3w';

  // ── GS Konfigurasi ID ─────────────────────────────────────────────────────
  static Future<String> getConfigSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConfigSheetId) ?? defaultConfigSheetId;
  }

  static Future<void> setConfigSheetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConfigSheetId, id.trim());
  }

  // ── Active User ───────────────────────────────────────────────────────────
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

  // ── Active Buku Keuangan ──────────────────────────────────────────────────
  static Future<String?> getActiveBookId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveBookId);
  }

  static Future<String?> getActiveBookName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveBookName);
  }

  static Future<void> setActiveBook(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveBookId, id);
    await prefs.setString(_keyActiveBookName, name);
  }

  static Future<void> clearActiveBook() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveBookId);
    await prefs.remove(_keyActiveBookName);
  }
}
