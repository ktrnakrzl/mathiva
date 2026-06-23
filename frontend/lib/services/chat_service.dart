import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class ChatService {
  // Create a reusable Dio client
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

  // Send a question to the backend and return the answer
  static Future<String> ask(String question) async {
    final response = await _dio.post(
      '/ask',
      queryParameters: {
        'question': question,
      },
    );

    return response.data['answer']?.toString() ??
        'Sorry, I could not get an answer.';
  }
}
