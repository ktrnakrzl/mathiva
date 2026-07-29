import '../models/user_profile.dart';

/// Thrown when registration or login fails (bad credentials, duplicate
/// email, network error, etc.) with a message safe to show the user.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Contract for registering and logging in a student account.
/// `ApiAuthRepository` hits the real `/auth/register`/`/auth/login` backend;
/// `MockAuthRepository` accepts anything, for offline development.
abstract class AuthRepository {
  /// Registers a new account. Throws [AuthException] if the email is
  /// already taken or the request otherwise fails.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? section,
  });

  /// Logs in and returns the JWT access token. Throws [AuthException] on
  /// incorrect credentials or a failed request.
  Future<String> login({
    required String email,
    required String password,
  });

  /// Logs in with a Google Sign-In ID token and returns Mathiva's JWT access
  /// token. Throws [AuthException] if Google verification or backend login
  /// fails.
  Future<String> loginWithGoogleIdToken(String idToken);

  /// Fetches the current token owner's profile from `/auth/me`. Requires a
  /// saved token (attached by the AuthInterceptor). Throws [AuthException]
  /// if the request fails.
  Future<UserProfile> getProfile();
}
