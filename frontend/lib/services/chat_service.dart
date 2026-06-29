import '../repositories/api/api_tutor_repository.dart';
import '../repositories/tutor_repository.dart';

/// Thin facade kept so existing call sites (e.g. `chat_screen.dart`) didn't
/// need to change when the tutor logic moved to the repository pattern.
/// `repository` defaults to the real backend but can be swapped (e.g. to
/// `MockTutorRepository()`, see `main.dart`'s `kUseMockBackend` flag).
class ChatService {
  static TutorRepository repository = ApiTutorRepository();

  /// Send a question to the backend and return the answer.
  static Future<String> ask(String question) => repository.ask(question);
}
