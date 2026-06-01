import 'package:mathiva/data/models/review_models.dart';
import 'package:mathiva/data/repositories/interfaces/review_repository.dart';

class MockReviewRepository implements ReviewRepository {
  @override
  Future<List<ReviewQuestion>> getReviewQueue(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ReviewQuestion(
        question_id: 'review_001',
        question_text: 'What is the next step after substituting a value into a function?',
        choices: const ['Simplify', 'Graph immediately', 'Ignore the variable', 'Change the formula'],
        topic_id: 'gen_math_functions',
        due_date: DateTime.now().toIso8601String(),
      ),
    ];
  }

  @override
  Future<ReviewResultResponse> submitReviewResult(String studentId, ReviewResult result) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ReviewResultResponse(next_review_date: DateTime.now().add(const Duration(days: 2)).toIso8601String(), updated_ease_factor: 2.6);
  }
}
