import '../tutor_repository.dart';

/// Offline stand-in for [TutorRepository] — streams a fixed answer word-by-word
/// with a small delay, so the chat UI (including its streaming render) can be
/// exercised without a running backend (e.g. when Ollama isn't up locally).
class MockTutorRepository implements TutorRepository {
  @override
  Stream<String> ask(String question) async* {
    final reply = 'This is a mock tutor answer for: "$question". '
        'Switch kUseMockBackend to false in api_constants.dart to use the real backend.';

    for (final word in reply.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 40));
      yield '$word ';
    }
  }
}
