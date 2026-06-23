import 'package:mathiva/data/models/review_models.dart';

abstract class ReviewRepository {
  Future<List<ReviewQuestion>> getReviewQueue(String studentId);
  Future<ReviewResultResponse> submitReviewResult(
      String studentId, ReviewResult result);
}
