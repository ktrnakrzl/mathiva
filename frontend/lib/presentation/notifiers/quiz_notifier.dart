import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/data/models/quiz_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/data/repositories/interfaces/quiz_repository.dart';

class QuizState {
  final QuizStartResponse? quiz;
  final AnswerResponse? lastAnswer;
  final QuizResult? result;
  const QuizState({this.quiz, this.lastAnswer, this.result});

  QuizState copyWith({QuizStartResponse? quiz, AnswerResponse? lastAnswer, QuizResult? result}) {
    return QuizState(quiz: quiz ?? this.quiz, lastAnswer: lastAnswer ?? this.lastAnswer, result: result ?? this.result);
  }
}

class QuizNotifier extends StateNotifier<AsyncValue<QuizState>> {
  final QuizRepository _repository;
  QuizNotifier(this._repository) : super(const AsyncValue.data(QuizState()));

  Future<void> startQuiz(String subjectId, String topicId, String difficulty) async {
    state = const AsyncValue.loading();
    try {
      final quiz = await _repository.startQuiz(
        QuizStartRequest(student_id: AppStrings.studentId, subject_id: subjectId, topic_id: topicId, difficulty: difficulty, item_count: 5),
      );
      state = AsyncValue.data(QuizState(quiz: quiz));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> submitAnswer(String quizId, String questionId, String answer) async {
    final current = state.value ?? const QuizState();
    state = const AsyncValue.loading();
    try {
      final response = await _repository.submitAnswer(AnswerRequest(quiz_id: quizId, question_id: questionId, student_answer: answer));
      state = AsyncValue.data(current.copyWith(lastAnswer: response));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> finishQuiz(String quizId) async {
    final current = state.value ?? const QuizState();
    state = const AsyncValue.loading();
    try {
      final result = await _repository.finishQuiz(quizId, AppStrings.studentId);
      state = AsyncValue.data(current.copyWith(result: result));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final quizNotifierProvider = StateNotifierProvider<QuizNotifier, AsyncValue<QuizState>>((ref) {
  return QuizNotifier(ref.read(quizRepositoryProvider));
});
