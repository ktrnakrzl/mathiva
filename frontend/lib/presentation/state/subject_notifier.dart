import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva_flutter/core/models/subject_model.dart';
import 'package:mathiva_flutter/data/providers/repository_providers.dart';

final subjectsProvider = FutureProvider<List<SubjectModel>>((ref) async {
  final subjectRepository = ref.watch(subjectRepositoryProvider);
  return subjectRepository.getAllSubjects();
});

final subjectByIdProvider =
    FutureProvider.family<SubjectModel, String>((ref, subjectId) async {
  final subjectRepository = ref.watch(subjectRepositoryProvider);
  return subjectRepository.getSubjectById(subjectId);
});

final topicsBySubjectProvider =
    FutureProvider.family<List<TopicModel>, String>((ref, subjectId) async {
  final subjectRepository = ref.watch(subjectRepositoryProvider);
  return subjectRepository.getTopicsBySubject(subjectId);
});

final topicByIdProvider =
    FutureProvider.family<TopicModel, String>((ref, topicId) async {
  final subjectRepository = ref.watch(subjectRepositoryProvider);
  return subjectRepository.getTopicById(topicId);
});
