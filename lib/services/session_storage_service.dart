import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorageService {
  static final SessionStorageService instance = SessionStorageService._internal();
  SessionStorageService._internal();

  static const String _keyAuthToken = 'js_auth_token';
  static const String _keyUserData = 'js_user_data';
  static const String _keyLastIdentifier = 'js_last_identifier';
  static const String _keySavedJobIds = 'js_saved_job_ids';
  static const String _keyThemeMode = 'js_theme_dark_mode';

  /// Saves active authentication session securely to persistent storage
  Future<void> saveSession({
    required String token,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthToken, token);

      if (userData != null) {
        await prefs.setString(_keyUserData, jsonEncode(userData));
      } else {
        await prefs.remove(_keyUserData);
      }
    } catch (_) {}
  }

  /// Restores saved authentication session from persistent storage
  Future<Map<String, dynamic>?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyAuthToken);

      if (token == null || token.isEmpty) {
        return null;
      }

      Map<String, dynamic>? userData;
      final userJson = prefs.getString(_keyUserData);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          userData = jsonDecode(userJson) as Map<String, dynamic>?;
        } catch (_) {}
      }

      return {
        'token': token,
        'userData': userData,
      };
    } catch (_) {
      return null;
    }
  }

  /// Saves updated user profile data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, jsonEncode(userData));
    } catch (_) {}
  }

  /// Clears active authentication session (for Logout)
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuthToken);
      await prefs.remove(_keyUserData);
    } catch (_) {}
  }

  /// Saves last entered login identifier (email/username) for quick auto-fill
  Future<void> saveLastIdentifier(String identifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastIdentifier, identifier.trim());
    } catch (_) {}
  }

  /// Retrieves last entered login identifier
  Future<String?> getLastIdentifier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastIdentifier);
    } catch (_) {
      return null;
    }
  }

  /// Saves bookmarked job IDs locally
  Future<void> saveBookmarkedJobIds(List<String> jobIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keySavedJobIds, jobIds);
    } catch (_) {}
  }

  /// Retrieves saved bookmarked job IDs
  Future<List<String>> getBookmarkedJobIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keySavedJobIds) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Saves dark mode preference
  Future<void> saveThemeMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyThemeMode, isDark);
    } catch (_) {}
  }

  /// Gets dark mode preference
  Future<bool?> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyThemeMode);
    } catch (_) {
      return null;
    }
  }
}
