import '../repositories/api/api_tutor_repository.dart';
import '../repositories/tutor_repository.dart';
import 'chat_store.dart';

/// Thin facade kept so existing call sites (e.g. `chat_screen.dart`) didn't
/// need to change when the tutor logic moved to the repository pattern.
/// `repository` defaults to the real backend but can be swapped (e.g. to
/// `MockTutorRepository()`, see `main.dart`'s `kUseMockBackend` flag).
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
