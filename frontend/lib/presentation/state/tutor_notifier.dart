import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/models/tutor_model.dart';
import 'package:mathiva/data/providers/repository_providers.dart';

class TutorNotifier extends StateNotifier<AsyncValue<TutorSession>> {
  final TutorRepository _tutorRepository;

  TutorNotifier(this._tutorRepository) : super(const AsyncValue.loading());

  Future<void> createSession(
    String userId, {
    String? topicId,
    String? questionId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _tutorRepository.createSession(
        userId,
        topicId: topicId,
        questionId: questionId,
      );
    });
  }

  Future<void> sendMessage(String sessionId, String message) async {
    final currentState = state;
    if (currentState is! AsyncValue<TutorSession> ||
        currentState.value == null) {
      return;
    }

    state = await AsyncValue.guard(() async {
      final session = await _tutorRepository.getSession(sessionId);
      await _tutorRepository.sendMessage(sessionId, message);
      return await _tutorRepository.getSession(sessionId);
    });
  }

  Future<void> endSession(String sessionId) async {
    state = await AsyncValue.guard(() async {
      await _tutorRepository.endSession(sessionId);
      return await _tutorRepository.getSession(sessionId);
    });
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

final tutorNotifierProvider =
    StateNotifierProvider<TutorNotifier, AsyncValue<TutorSession>>((ref) {
  final tutorRepository = ref.watch(tutorRepositoryProvider);
  return TutorNotifier(tutorRepository);
});

final tutorSessionProvider =
    FutureProvider.family<TutorSession, String>((ref, sessionId) async {
  final tutorRepository = ref.watch(tutorRepositoryProvider);
  return tutorRepository.getSession(sessionId);
});
