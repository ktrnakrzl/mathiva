import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/data/models/tutor_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/data/repositories/interfaces/tutor_repository.dart';

class TutorNotifier extends StateNotifier<AsyncValue<TutorResponse?>> {
  final TutorRepository _repository;

  TutorNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> askQuestion(String question, String subjectId, String topicId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.askQuestion(
        TutorRequest(student_id: AppStrings.studentId, question: question, subject_id: subjectId, topic_id: topicId),
      );
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final tutorNotifierProvider = StateNotifierProvider<TutorNotifier, AsyncValue<TutorResponse?>>((ref) {
  return TutorNotifier(ref.read(tutorRepositoryProvider));
});
