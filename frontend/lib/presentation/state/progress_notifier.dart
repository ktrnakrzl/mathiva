import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/models/progress_model.dart';
import 'package:mathiva/data/providers/repository_providers.dart';

final userProgressProvider =
    FutureProvider.family<ProgressSnapshot, String>((ref, userId) async {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return progressRepository.getUserProgress(userId);
});

final subjectProgressProvider =
    FutureProvider.family<SubjectProgress, ({String userId, String subjectId})>(
  (ref, params) async {
    final progressRepository = ref.watch(progressRepositoryProvider);
    return progressRepository.getSubjectProgress(
        params.userId, params.subjectId);
  },
);

final rewardInfoProvider =
    FutureProvider.family<RewardInfo, String>((ref, userId) async {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return progressRepository.getRewardInfo(userId);
});

class ProgressUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final ProgressRepository _progressRepository;

  ProgressUpdateNotifier(this._progressRepository)
      : super(const AsyncValue.data(null));

  Future<void> updateProgress(
    String userId,
    int pointsEarned,
    String topicId,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _progressRepository.updateProgress(userId, pointsEarned, topicId);
    });
  }
}

final progressUpdateNotifierProvider =
    StateNotifierProvider<ProgressUpdateNotifier, AsyncValue<void>>((ref) {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return ProgressUpdateNotifier(progressRepository);
});
