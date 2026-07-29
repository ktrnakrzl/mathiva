import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT access token across app restarts. This is the app's
/// first real on-disk storage -- everything else (AppPreferences) is
/// in-memory only and resets when the app closes.
class AuthStorage {
  static const _tokenKey = 'auth_access_token';
  static final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);

  static Future<void> init() async {
    isAuthenticated.value = await hasToken();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    isAuthenticated.value = true;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    isAuthenticated.value = false;
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
