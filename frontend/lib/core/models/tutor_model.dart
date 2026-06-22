import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutor_model.freezed.dart';
part 'tutor_model.g.dart';

enum MessageSender { user, tutor }

@freezed
class TutorMessage with _$TutorMessage {
  const factory TutorMessage({
    required String messageId,
    required MessageSender sender,
    required String content,
    required String? latexFormula,
    required DateTime timestamp,
    required List<String>? references, // RAG references
  }) = _TutorMessage;

  factory TutorMessage.fromJson(Map<String, dynamic> json) =>
      _$TutorMessageFromJson(json);
}

@freezed
class TutorSession with _$TutorSession {
  const factory TutorSession({
    required String sessionId,
    required String userId,
    required String? topicId,
    required String? questionId,
    required List<TutorMessage> messages,
    required DateTime startedAt,
    required DateTime? endedAt,
  }) = _TutorSession;

  factory TutorSession.fromJson(Map<String, dynamic> json) =>
      _$TutorSessionFromJson(json);
}
