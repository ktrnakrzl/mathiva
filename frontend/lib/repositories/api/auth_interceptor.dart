import 'package:dio/dio.dart';

import '../../services/auth_storage.dart';

/// Attaches `Authorization: Bearer <token>` to every outgoing request, read
/// fresh from [AuthStorage] each time (the token can change between requests,
/// e.g. after a fresh login). Add this to the Dio instance of any repository
/// that calls an authenticated backend endpoint.
///
/// This is the first place in the app that actually *uses* the stored JWT --
/// `AuthStorage.saveToken` was being called on login/register, but nothing
/// ever read it back until now.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A 401 means the stored JWT is missing, malformed, or (most commonly)
    // expired -- the token only lives 24h. Drop it so the app doesn't keep
    // retrying with a dead token; the user re-authenticates from the login
    // screen, which writes a fresh one. Callers can detect the 401 on their
    // own request to show a "session expired, log in again" message.
    if (err.response?.statusCode == 401) {
      AuthStorage.clearToken();
    }
    handler.next(err);
  }
}
