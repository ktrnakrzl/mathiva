import '../repositories/api/api_tutor_repository.dart';
import '../repositories/tutor_repository.dart';
import 'chat_store.dart';

/// Thin facade over the backend tutor repository.
class ChatService {
  static TutorRepository repository = ApiTutorRepository();

  /// Send a question to the backend and stream the answer back as incremental
  /// text chunks (concatenate them for the full reply).
  static Stream<String> ask(
    String question, {
    List<ChatMessage> history = const [],
  }) {
    return repository.ask(
      question,
      history: history
          .map(
            (message) => TutorChatTurn(
              role: message.isUser ? 'user' : 'assistant',
              text: message.text,
            ),
          )
          .toList(growable: false),
    );
  }
}
