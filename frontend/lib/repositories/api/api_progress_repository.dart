import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../progress_repository.dart';
import 'auth_interceptor.dart';

/// Real implementation of [ProgressRepository] -- calls the FastAPI backend's
/// auth-gated `/api/quiz/submit` and `/api/user/progress` endpoints. The
/// [AuthInterceptor] attaches the logged-in user's JWT to every request.
class ApiProgressRepository implements ProgressRepository {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor());

  @override
  Future<void> submitAttempt({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
    String? selectedAnswer,
    required bool isCorrect,
    required int elapsedSeconds,
  }) async {
    await _dio.post('/api/quiz/submit', data: {
      'subject_id': subjectId,
      'topic_id': topicId,
      'lesson_id': lessonId,
      'concept_id': conceptId,
      'difficulty': difficulty,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'elapsed_seconds': elapsedSeconds,
    });
  }

  @override
  Future<UserProgress> getProgress() async {
    final response = await _dio.get('/api/user/progress');
    return UserProgress.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GeneratedQuestion> fetchNextQuestion({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
  }) async {
    final response = await _dio.get('/api/quiz/next', queryParameters: {
      'subject_id': subjectId,
      'topic_id': topicId,
      'lesson_id': lessonId,
      'concept_id': conceptId,
      'difficulty': difficulty,
    });
    return GeneratedQuestion.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GeneratedQuestion> fetchAdaptiveQuestion({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required List<String> candidateConcepts,
  }) async {
    final response = await _dio.post('/api/quiz/next-adaptive', data: {
      'subject_id': subjectId,
      'topic_id': topicId,
      'lesson_id': lessonId,
      'candidate_concepts': candidateConcepts,
    });
    return GeneratedQuestion.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AnswerResult> submitAnswer({
    required int questionId,
    required String selectedAnswer,
    required int elapsedSeconds,
  }) async {
    final response = await _dio.post('/api/quiz/answer', data: {
      'question_id': questionId,
      'selected_answer': selectedAnswer,
      'elapsed_seconds': elapsedSeconds,
    });
    return AnswerResult.fromJson(response.data as Map<String, dynamic>);
  }
}
