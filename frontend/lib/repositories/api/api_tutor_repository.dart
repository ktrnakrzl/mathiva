import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../tutor_repository.dart';
import 'auth_interceptor.dart';

/// Real implementation of [TutorRepository] — calls the FastAPI backend's
/// RAG-based `/api/ask/stream` endpoint (auth-gated), which streams the answer
/// as plain text so the chat UI can render it token-by-token.
class ApiTutorRepository implements TutorRepository {
  // Reusable Dio client, configured the same way the old ChatService used.
  // The [AuthInterceptor] attaches the logged-in user's JWT -- the ask endpoint
  // is auth-gated, so without it every request would 401.
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
  Stream<String> ask(String question) async* {
    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        '/api/ask/stream',
        queryParameters: {
          'question': question,
        },
        // Get the raw byte stream instead of a buffered body, so we can forward
        // each chunk to the UI as it arrives.
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException {
      final fallback = await _dio.post<Map<String, dynamic>>(
        '/api/ask',
        queryParameters: {
          'question': question,
        },
      );
      final answer = fallback.data?['answer']?.toString();
      if (answer != null && answer.isNotEmpty) {
        yield answer;
      }
      return;
    }

    final body = response.data;
    if (body == null) return;

    // utf8.decoder handles multi-byte characters that get split across network
    // chunks; each decoded string is a piece of the answer for the UI to append.
    yield* utf8.decoder.bind(body.stream);
  }
}
