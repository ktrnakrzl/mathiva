import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../tutor_repository.dart';
import 'auth_interceptor.dart';

/// Real implementation of [TutorRepository] — calls the FastAPI backend's
/// RAG-based `/api/ask` endpoint, which now requires a valid JWT.
class ApiTutorRepository implements TutorRepository {
  // Reusable Dio client, configured the same way the old ChatService used.
  // The [AuthInterceptor] attaches the logged-in user's JWT -- `/api/ask` is
  // auth-gated, so without it every request would 401.
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor());

  @override
  Future<String> ask(String question) async {
    final response = await _dio.post(
      '/api/ask',
      queryParameters: {
        'question': question,
      },
    );

    return response.data['answer']?.toString() ??
        'Sorry, I could not get an answer.';
  }
}
