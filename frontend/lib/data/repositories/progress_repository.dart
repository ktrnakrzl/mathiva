import 'package:mathiva_flutter/core/models/progress_model.dart';

abstract class ProgressRepository {
  Future<ProgressSnapshot> getUserProgress(String userId);
  
  Future<SubjectProgress> getSubjectProgress(
    String userId,
    String subjectId,
  );
  
  Future<RewardInfo> getRewardInfo(String userId);
  
  Future<void> updateProgress(
    String userId,
    int pointsEarned,
    String topicId,
  );
}
