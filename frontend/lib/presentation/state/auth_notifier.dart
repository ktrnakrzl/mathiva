import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva_flutter/core/models/user_model.dart';
import 'package:mathiva_flutter/data/providers/repository_providers.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final authRepository = AuthRepository;

  AuthNotifier(this.authRepository)
      : super(const AsyncValue.loading());

  final AuthRepository _authRepository;

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _authRepository.login(email, password);
      return response.user;
    });
  }

  Future<void> signup(
    String username,
    String email,
    String password,
    String gradeLevel,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _authRepository.signup(
        username,
        email,
        password,
        gradeLevel,
      );
      return response.user;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.logout();
      return null;
    });
  }

  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _authRepository.getCurrentUser();
    });
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
