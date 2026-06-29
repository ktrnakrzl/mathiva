import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../auth_repository.dart';

/// Real implementation of [AuthRepository] -- calls the FastAPI backend's
/// `/auth/register` and `/auth/login` endpoints (unprefixed, same as
/// `/health` and `/quiz`).
class ApiAuthRepository implements AuthRepository {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

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
