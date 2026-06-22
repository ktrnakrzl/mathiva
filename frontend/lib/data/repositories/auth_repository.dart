import 'package:mathiva_flutter/core/models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> signup(
    String username,
    String email,
    String password,
    String gradeLevel,
  );
  Future<void> logout();
  Future<AuthResponse?> refreshToken(String refreshToken);
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
}
