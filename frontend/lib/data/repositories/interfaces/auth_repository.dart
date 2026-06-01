import 'package:mathiva/data/models/auth_models.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<RegisterResponse> register(RegisterRequest request);
}
