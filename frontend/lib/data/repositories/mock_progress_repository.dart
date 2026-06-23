import 'package:mathiva/data/repositories/progress_repository.dart';
import 'package:mathiva/data/repositories/mock_data.dart';
import 'package:mathiva/core/models/progress_model.dart';

class MockProgressRepository implements ProgressRepository {
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 700));

  @override
  Future<ProgressSnapshot> getUserProgress(String userId) async {
    await _delay();
    return MockData.sampleProgressSnapshot;
  }

  @override
  Future<SubjectProgress> getSubjectProgress(
    String userId,
    String subjectId,
  ) async {
    await _delay();
    final progress = MockData.sampleProgressSnapshot.subjectProgress[subjectId];
    if (progress == null) {
      throw Exception('Subject progress not found');
    }
    return progress;
  }

  @override
  Future<RewardInfo> getRewardInfo(String userId) async {
    await _delay();
    return MockData.sampleRewardInfo;
  }

  @override
  Future<void> updateProgress(
    String userId,
    int pointsEarned,
    String topicId,
  ) async {
    await _delay();
    // In real implementation, this would update the database
    print(
        '[MockProgress] Updated user $userId with $pointsEarned points for topic $topicId');
  }
}
