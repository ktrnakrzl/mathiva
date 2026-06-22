import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

enum DifficultyLevel { easy, medium, hard }

enum QuestionType { multipleChoice, shortAnswer, derivation }

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String questionId,
    required String topicId,
    required String questionText,
    required String? latexFormula,
    required DifficultyLevel difficulty,
    required QuestionType type,
    required List<String> options, // for multiple choice
    required String correctAnswer,
    required String explanation,
    required String? solutionSteps, // JSON string of step-by-step solution
    required int pointsReward,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}

@freezed
class QuizSession with _$QuizSession {
  const factory QuizSession({
    required String sessionId,
    required String userId,
    required String topicId,
    required List<QuestionModel> questions,
    required int currentQuestionIndex,
    required List<String> userAnswers,
    required List<bool> isCorrectAnswers,
    required int scorePercentage,
    required bool isCompleted,
    required DateTime startedAt,
    required DateTime? completedAt,
  }) = _QuizSession;

  factory QuizSession.fromJson(Map<String, dynamic> json) =>
      _$QuizSessionFromJson(json);
}

@freezed
class QuestionReview with _$QuestionReview {
  const factory QuestionReview({
    required String questionId,
    required String userAnswer,
    required String correctAnswer,
    required bool isCorrect,
    required int pointsEarned,
    required int daysUntilNextReview,
  }) = _QuestionReview;

  factory QuestionReview.fromJson(Map<String, dynamic> json) =>
      _$QuestionReviewFromJson(json);
}
