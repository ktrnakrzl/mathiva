import '../repositories/api/api_progress_repository.dart';
import '../repositories/progress_repository.dart';

export '../repositories/progress_repository.dart';

/// Thin facade over [ProgressRepository], matching the ChatService /
/// SolverService pattern. `repository` defaults to the real backend but can
/// be swapped to `MockProgressRepository()` (see `main.dart`'s
/// `kUseMockBackend` flag).
class ProgressService {
  static ProgressRepository repository = ApiProgressRepository();

  static Future<void> submitAttempt({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
    String? selectedAnswer,
    required bool isCorrect,
    required int elapsedSeconds,
  }) =>
      repository.submitAttempt(
        subjectId: subjectId,
        topicId: topicId,
        lessonId: lessonId,
        conceptId: conceptId,
        difficulty: difficulty,
        selectedAnswer: selectedAnswer,
        isCorrect: isCorrect,
        elapsedSeconds: elapsedSeconds,
      );

  static Future<UserProgress> getProgress() => repository.getProgress();

  static Future<GeneratedQuestion> fetchNextQuestion({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
  }) =>
      repository.fetchNextQuestion(
        subjectId: subjectId,
        topicId: topicId,
        lessonId: lessonId,
        conceptId: conceptId,
        difficulty: difficulty,
      );

  static Future<GeneratedQuestion> fetchAdaptiveQuestion({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required List<String> candidateConcepts,
  }) =>
      repository.fetchAdaptiveQuestion(
        subjectId: subjectId,
        topicId: topicId,
        lessonId: lessonId,
        candidateConcepts: candidateConcepts,
      );

  static Future<AnswerResult> submitAnswer({
    required int questionId,
    required String selectedAnswer,
    required int elapsedSeconds,
  }) =>
      repository.submitAnswer(
        questionId: questionId,
        selectedAnswer: selectedAnswer,
        elapsedSeconds: elapsedSeconds,
      );
}
