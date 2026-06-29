/// Contract for asking the AI math tutor a question and getting back an
/// answer. `ApiTutorRepository` hits the real backend; `MockTutorRepository`
/// returns canned data so the UI can be developed/demoed without a backend.
abstract class TutorRepository {
  /// Sends [question] to the tutor and returns its answer.
  Future<String> ask(String question);
}
