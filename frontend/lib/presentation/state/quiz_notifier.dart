import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/models/question_model.dart';
import 'package:mathiva/data/providers/repository_providers.dart';

class QuizNotifier extends StateNotifier<AsyncValue<QuizSession>> {
  final QuestionRepository _questionRepository;

  QuizNotifier(this._questionRepository) : super(const AsyncValue.loading());

  Future<void> createSession(
    String userId,
    String topicId,
    int numQuestions,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _questionRepository.createQuizSession(
        userId,
        topicId,
        numQuestions,
      );
    });
  }

  Future<void> submitAnswer(
      String sessionId, int questionIndex, String answer) async {
    final currentState = state;
    if (currentState is! AsyncValue<QuizSession> ||
        currentState.value == null) {
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _questionRepository.submitAnswer(
        sessionId,
        questionIndex,
        answer,
      );
    });
  }

  Future<void> completeSession(String sessionId) async {
    state = await AsyncValue.guard(() async {
      return await _questionRepository.completeQuizSession(sessionId);
    });
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

final quizNotifierProvider =
    StateNotifierProvider<QuizNotifier, AsyncValue<QuizSession>>((ref) {
  final questionRepository = ref.watch(questionRepositoryProvider);
  return QuizNotifier(questionRepository);
});

final quizSessionProvider =
    FutureProvider.family<QuizSession, String>((ref, sessionId) async {
  final questionRepository = ref.watch(questionRepositoryProvider);
  return questionRepository.getQuizSession(sessionId);
});

final reviewQueueProvider = FutureProvider.family<List<QuestionReview>, String>(
  (ref, userId) async {
    final questionRepository = ref.watch(questionRepositoryProvider);
    return questionRepository.getReviewQueue(userId);
  },
);
