import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject_model.freezed.dart';
part 'subject_model.g.dart';

@freezed
class SubjectModel with _$SubjectModel {
  const factory SubjectModel({
    required String subjectId,
    required String name,
    required String description,
    required List<TopicModel> topics,
    required int masteredTopics,
  }) = _SubjectModel;

  factory SubjectModel.fromJson(Map<String, dynamic> json) =>
      _$SubjectModelFromJson(json);
}

@freezed
class TopicModel with _$TopicModel {
  const factory TopicModel({
    required String topicId,
    required String name,
    required String subjectId,
    required double masteryPercentage, // 0-100
    required int questionsAttempted,
    required int questionsCorrect,
    required DateTime lastReviewedAt,
  }) = _TopicModel;

  factory TopicModel.fromJson(Map<String, dynamic> json) =>
      _$TopicModelFromJson(json);
}
