import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/data/models/auth_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/data/repositories/interfaces/auth_repository.dart';

class AuthNotifier extends StateNotifier<AsyncValue<LoginResponse?>> {
  final AuthRepository _repository;
  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.login(LoginRequest(email: email, password: password));
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<LoginResponse?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
