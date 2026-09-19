import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_store.dart';

/// Persists the JWT access token across app restarts.
class AuthStorage {
  static const _tokenKey = 'auth_access_token';
  static final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
  static String? _cachedToken;

  static Future<void> init() async {
    _cachedToken = await getToken();
    isAuthenticated.value = await hasToken();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final previousToken = _cachedToken ?? prefs.getString(_tokenKey);
    await prefs.setString(_tokenKey, token);
    _cachedToken = token;
    if (previousToken != token) {
      ChatStore.reset();
    }
    isAuthenticated.value = true;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _cachedToken = null;
    ChatStore.reset();
    isAuthenticated.value = false;
  }

  static Future<bool> hasToken() async {
    final token = _cachedToken ?? await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Stable suffix for per-account local caches. The backend JWT stores the
  /// user id in `sub`; decoding it locally is only for namespacing device data,
  /// not for trusting auth. If the token is not a JWT (demo mode), use a shared
  /// demo namespace rather than mixing with real accounts.
  static String get storageScope {
    final token = _cachedToken;
    if (token == null || token.isEmpty) return 'signed_out';

    final parts = token.split('.');
    if (parts.length != 3) return 'demo';

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final sub = payload['sub']?.toString();
      if (sub != null && sub.isNotEmpty) return 'user_$sub';
    } catch (_) {
      // Fall through to a non-account namespace.
    }
    return 'unknown_user';
  }
}
