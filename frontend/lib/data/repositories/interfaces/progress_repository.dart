import 'package:mathiva/data/models/progress_models.dart';

abstract class ProgressRepository {
  Future<StudentProgress> getProgress(String studentId);
  Future<List<TopicMastery>> getMastery(String studentId);
  Future<Rewards> getRewards(String studentId);
}
