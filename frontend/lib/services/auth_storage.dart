import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT access token across app restarts. This is the app's
/// first real on-disk storage -- everything else (AppPreferences) is
/// in-memory only and resets when the app closes.
class AuthStorage {
  static const _tokenKey = 'auth_access_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
