import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_model.freezed.dart';
part 'progress_model.g.dart';

enum MasteryLevel { notStarted, learning, intermediate, proficient, mastered }

@freezed
class ProgressSnapshot with _$ProgressSnapshot {
  const factory ProgressSnapshot({
    required String userId,
    required int totalPointsEarned,
    required int currentStreak,
    required int longestStreak,
    required int totalQuestionsAttempted,
    required int totalQuestionsCorrect,
    required int totalSessionsCompleted,
    required Map<String, SubjectProgress> subjectProgress,
    required DateTime lastActivityAt,
  }) = _ProgressSnapshot;

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ProgressSnapshotFromJson(json);
}

@freezed
class SubjectProgress with _$SubjectProgress {
  const factory SubjectProgress({
    required String subjectId,
    required int topicsMastered,
    required int totalTopics,
    required double overallMasteryPercentage,
    required Map<String, double> topicMasteryMap, // topicId -> percentage
    required List<DailyActivityPoint> dailyActivity, // last 30 days
  }) = _SubjectProgress;

  factory SubjectProgress.fromJson(Map<String, dynamic> json) =>
      _$SubjectProgressFromJson(json);
}

@freezed
class DailyActivityPoint with _$DailyActivityPoint {
  const factory DailyActivityPoint({
    required DateTime date,
    required int pointsEarned,
    required int questionsAttempted,
  }) = _DailyActivityPoint;

  factory DailyActivityPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityPointFromJson(json);
}

@freezed
class RewardInfo with _$RewardInfo {
  const factory RewardInfo({
    required int level,
    required int totalPointsForLevel,
    required int pointsNeededForNextLevel,
    required List<Badge> unlockedBadges,
    required List<Badge> lockedBadges,
  }) = _RewardInfo;

  factory RewardInfo.fromJson(Map<String, dynamic> json) =>
      _$RewardInfoFromJson(json);
}

@freezed
class Badge with _$Badge {
  const factory Badge({
    required String badgeId,
    required String name,
    required String description,
    required String iconUrl,
    required bool isUnlocked,
    required DateTime? unlockedAt,
    required int pointsReward,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) =>
      _$BadgeFromJson(json);
}
