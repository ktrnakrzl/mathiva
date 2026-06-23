import 'package:mathiva/data/models/auth_models.dart';
import 'package:mathiva/data/repositories/interfaces/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<LoginResponse> login(LoginRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return LoginResponse(
        student_id: 'student_001',
        name: 'Mathiva Student',
        grade_level: 'Grade 11',
        token: 'mock-token');
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return RegisterResponse(student_id: 'student_001', token: 'mock-token');
  }
}
