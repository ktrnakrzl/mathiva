import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../models/user_profile.dart';
import '../auth_repository.dart';
import 'auth_interceptor.dart';

/// Real implementation of [AuthRepository] -- calls the FastAPI backend's
/// `/auth/register`, `/auth/login`, and `/auth/me` endpoints (unprefixed, same
/// as `/health` and `/quiz`).
class ApiAuthRepository implements AuthRepository {
  // The [AuthInterceptor] attaches the stored JWT when there is one. Register
  // and login don't need it (no token yet), but `/auth/me` does -- it's read
  // right after login, once the token has been saved.
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor());

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? section,
  }) async {
    try {
      await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (section != null) 'section': section,
      });
    } on DioException catch (e) {
      throw AuthException(_messageFor(e, 'Could not create your account.'));
    }
  }

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data['access_token'] as String;
    } on DioException catch (e) {
      throw AuthException(_messageFor(e, 'Could not log in.'));
    }
  }

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_messageFor(e, 'Could not load your profile.'));
    }
  }

  /// FastAPI's HTTPException puts a human-readable message in `detail`
  /// (e.g. 401/409). A 422 validation failure instead puts a *list* of
  /// error objects there, each with a `msg` field -- surface the first one.
  /// The frontend validates email/password before submitting, so this
  /// mainly guards against edge cases the client-side checks miss.
  String _messageFor(DioException e, String defaultMessage) {
    final detail = e.response?.data is Map ? e.response?.data['detail'] : null;

    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final msg = detail.first['msg']?.toString();
      if (msg != null) {
        return msg.replaceFirst('Value error, ', '');
      }
    }
    if (detail is String) return detail;

    return defaultMessage;
  }
}
