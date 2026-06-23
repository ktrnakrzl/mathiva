import 'package:mathiva/core/models/tutor_model.dart';

abstract class TutorRepository {
  Future<TutorSession> createSession(
    String userId, {
    String? topicId,
    String? questionId,
  });

  Future<TutorSession> getSession(String sessionId);

  Future<TutorMessage> sendMessage(
    String sessionId,
    String message,
  );

  Future<void> endSession(String sessionId);

  Future<List<TutorSession>> getUserSessions(String userId);
}
