import 'package:mathiva/data/models/progress_models.dart';
import 'package:mathiva/data/repositories/interfaces/progress_repository.dart';

class MockProgressRepository implements ProgressRepository {
  @override
  Future<StudentProgress> getProgress(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return StudentProgress(
      points_total: 180,
      streak_days: 4,
      subjects: [
        SubjectProgress(
            subject_id: 'gen_math', mastery_percent: 64, topics_completed: 3),
        SubjectProgress(
            subject_id: 'stats', mastery_percent: 42, topics_completed: 2),
      ],
    );
  }

  @override
  Future<List<TopicMastery>> getMastery(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      TopicMastery(
          topic_id: 'gen_math_functions',
          topic_name: 'Functions',
          mastery_level: 70,
          last_practiced: '2026-06-01'),
      TopicMastery(
          topic_id: 'stats_probability',
          topic_name: 'Probability',
          mastery_level: 48,
          last_practiced: '2026-05-30'),
    ];
  }

  @override
  Future<Rewards> getRewards(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Rewards(
      points: 180,
      rank: 'Bronze',
      badges: [
        Badge(
            badge_id: 'badge_001',
            name: 'First Quiz Passed',
            earned_date: '2026-06-01')
      ],
    );
  }
}
