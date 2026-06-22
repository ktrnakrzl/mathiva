import 'package:dio/dio.dart';
import 'package:mathiva/data/models/auth_models.dart';
import 'package:mathiva/data/repositories/interfaces/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;
  ApiAuthRepository(this._dio);

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post('/auth/login', data: request.toJson());
    return LoginResponse.fromJson(response.data);
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _dio.post('/auth/register', data: request.toJson());
    return RegisterResponse.fromJson(response.data);
  }
}
