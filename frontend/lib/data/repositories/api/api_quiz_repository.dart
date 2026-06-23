import 'package:dio/dio.dart';
import 'package:mathiva/data/models/quiz_models.dart';
import 'package:mathiva/data/repositories/interfaces/quiz_repository.dart';

class ApiQuizRepository implements QuizRepository {
  final Dio _dio;
  ApiQuizRepository(this._dio);

  @override
  Future<QuizStartResponse> startQuiz(QuizStartRequest request) async {
    final response = await _dio.post('/quiz/start', data: request.toJson());
    return QuizStartResponse.fromJson(response.data);
  }

  @override
  Future<AnswerResponse> submitAnswer(AnswerRequest request) async {
    final response =
        await _dio.post('/quiz/submit-answer', data: request.toJson());
    return AnswerResponse.fromJson(response.data);
  }

  @override
  Future<QuizResult> finishQuiz(String quizId, String studentId) async {
    final response = await _dio.post('/quiz/finish',
        data: {'quiz_id': quizId, 'student_id': studentId});
    return QuizResult.fromJson(response.data);
  }
}
