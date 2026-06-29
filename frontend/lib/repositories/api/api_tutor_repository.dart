import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../tutor_repository.dart';

/// Real implementation of [TutorRepository] — calls the FastAPI backend's
/// RAG-based `/api/ask` endpoint.
class ApiTutorRepository implements TutorRepository {
  // Reusable Dio client, configured the same way the old ChatService used.
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

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
