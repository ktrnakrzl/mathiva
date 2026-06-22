import 'package:mathiva_flutter/data/repositories/tutor_repository.dart';
import 'package:mathiva_flutter/data/repositories/mock_data.dart';
import 'package:mathiva_flutter/core/models/tutor_model.dart';

class MockTutorRepository implements TutorRepository {
  final Map<String, TutorSession> _sessions = {};
  
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 1200));

  @override
  Future<TutorSession> createSession(
    String userId, {
    String? topicId,
    String? questionId,
  }) async {
    await _delay();
    
    final session = TutorSession(
      sessionId: 'tutor_session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      topicId: topicId,
      questionId: questionId,
      messages: [],
      startedAt: DateTime.now(),
      endedAt: null,
    );
    
    _sessions[session.sessionId] = session;
    return session;
  }

  @override
  Future<TutorSession> getSession(String sessionId) async {
    await _delay();
    return _sessions[sessionId] ??
        (throw Exception('Session not found'));
  }

  @override
  Future<TutorMessage> sendMessage(
    String sessionId,
    String message,
  ) async {
    final session = _sessions[sessionId];
    if (session == null) throw Exception('Session not found');

    // Add user message
    final userMessage = TutorMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content: message,
      latexFormula: null,
      timestamp: DateTime.now(),
      references: null,
    );

    var updatedMessages = [...session.messages, userMessage];
    _sessions[sessionId] = session.copyWith(messages: updatedMessages);

    // Simulate tutor thinking and responding
    await _delay();

    final tutorResponse = TutorMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}_tutor',
      sender: MessageSender.tutor,
      content: _generateTutorResponse(message),
      latexFormula: _generateLatexResponse(message),
      timestamp: DateTime.now().add(const Duration(milliseconds: 500)),
      references: ['RAG_doc_1.pdf', 'course_material_ch3.pdf'],
    );

    updatedMessages = [...updatedMessages, tutorResponse];
    _sessions[sessionId] = session.copyWith(messages: updatedMessages);
    
    return tutorResponse;
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _delay();
    final session = _sessions[sessionId];
    if (session == null) throw Exception('Session not found');

    _sessions[sessionId] = session.copyWith(
      endedAt: DateTime.now(),
    );
  }

  @override
  Future<List<TutorSession>> getUserSessions(String userId) async {
    await _delay();
    return _sessions.values
        .where((s) => s.userId == userId)
        .toList();
  }

  String _generateTutorResponse(String userMessage) {
    final responses = [
      'Great question! Let me break this down for you step by step. First, we need to understand the fundamental concept...',
      'That\'s an excellent observation! This relates to the concept we learned earlier. Let me explain the connection...',
      'I see what you\'re thinking. Let me clarify this for you with an example. Consider...',
      'Good attempt! You\'re on the right track. Here\'s the key insight you might be missing...',
      'Perfect! You\'re demonstrating good understanding. Now let\'s extend this to the more complex scenario...',
    ];
    return responses[userMessage.hashCode % responses.length];
  }

  String? _generateLatexResponse(String userMessage) {
    if (userMessage.toLowerCase().contains('formula') ||
        userMessage.toLowerCase().contains('equation')) {
      return r'E = mc^2 \text{ or } \frac{d^2x}{dt^2} + \omega^2 x = 0';
    }
    return null;
  }
}

extension on TutorSession {
  TutorSession copyWith({
    String? sessionId,
    String? userId,
    String? topicId,
    String? questionId,
    List<TutorMessage>? messages,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return TutorSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      questionId: questionId ?? this.questionId,
      messages: messages ?? this.messages,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
