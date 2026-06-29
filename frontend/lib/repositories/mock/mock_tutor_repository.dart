import '../tutor_repository.dart';

/// Offline stand-in for [TutorRepository] — returns a fixed answer after a
/// short simulated delay, so the chat UI can be exercised without a running
/// backend (e.g. when Ollama isn't up locally).
class MockTutorRepository implements TutorRepository {
  @override
  Future<String> ask(String question) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return 'This is a mock tutor answer for: "$question". '
        'Switch kUseMockBackend to false in api_constants.dart to use the real backend.';
  }
}
