import 'package:dio/dio.dart';
import 'package:mathiva/data/models/review_models.dart';
import 'package:mathiva/data/repositories/interfaces/review_repository.dart';

class ApiReviewRepository implements ReviewRepository {
  final Dio _dio;
  ApiReviewRepository(this._dio);

  @override
  Future<List<ReviewQuestion>> getReviewQueue(String studentId) async {
    final response = await _dio.get('/students/$studentId/review-queue');
    return (response.data as List).map((item) => ReviewQuestion.fromJson(item)).toList();
  }

  @override
  Future<ReviewResultResponse> submitReviewResult(String studentId, ReviewResult result) async {
    final response = await _dio.post('/students/$studentId/review-result', data: result.toJson());
    return ReviewResultResponse.fromJson(response.data);
  }
}
