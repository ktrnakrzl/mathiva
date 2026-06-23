import 'package:mathiva/data/repositories/auth_repository.dart';
import 'package:mathiva/data/repositories/mock_data.dart';
import 'package:mathiva/core/models/user_model.dart';

class MockAuthRepository implements AuthRepository {
  String? _currentToken;
  UserModel? _currentUser;

  // Simulate network delay
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 800));

  @override
  Future<AuthResponse> login(String email, String password) async {
    await _delay();
    if (email == 'john@ubnhs.edu.ph' && password == 'password123') {
      _currentToken = MockData.authResponse.accessToken;
      _currentUser = MockData.sampleUser;
      return MockData.authResponse;
    }
    throw Exception('Invalid email or password');
  }

  @override
  Future<AuthResponse> signup(
    String username,
    String email,
    String password,
    String gradeLevel,
  ) async {
    await _delay();
    final newUser = UserModel(
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      email: email,
      gradeLevel: gradeLevel,
      totalPoints: 0,
      streakDays: 0,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    final response = AuthResponse(
      accessToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      user: newUser,
    );

    _currentToken = response.accessToken;
    _currentUser = newUser;
    return response;
  }

  @override
  Future<void> logout() async {
    await _delay();
    _currentToken = null;
    _currentUser = null;
  }

  @override
  Future<AuthResponse?> refreshToken(String refreshToken) async {
    await _delay();
    if (refreshToken == MockData.authResponse.refreshToken) {
      return MockData.authResponse;
    }
    return null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await _delay();
    return _currentUser ?? MockData.sampleUser;
  }

  @override
  Future<bool> isLoggedIn() async {
    await _delay();
    return _currentToken != null;
  }
}
