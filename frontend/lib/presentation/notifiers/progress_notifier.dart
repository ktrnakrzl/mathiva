import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/data/models/progress_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/data/repositories/interfaces/progress_repository.dart';

class ProgressNotifier extends StateNotifier<AsyncValue<StudentProgress?>> {
  final ProgressRepository _repository;
  ProgressNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> loadProgress() async {
    state = const AsyncValue.loading();
    try {
      final progress = await _repository.getProgress(AppStrings.studentId);
      state = AsyncValue.data(progress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final progressNotifierProvider = StateNotifierProvider<ProgressNotifier, AsyncValue<StudentProgress?>>((ref) {
  return ProgressNotifier(ref.read(progressRepositoryProvider));
});
