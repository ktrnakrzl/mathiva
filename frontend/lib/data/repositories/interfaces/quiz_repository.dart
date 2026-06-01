import 'package:mathiva/data/models/quiz_models.dart';

abstract class QuizRepository {
  Future<QuizStartResponse> startQuiz(QuizStartRequest request);
  Future<AnswerResponse> submitAnswer(AnswerRequest request);
  Future<QuizResult> finishQuiz(String quizId, String studentId);
}
