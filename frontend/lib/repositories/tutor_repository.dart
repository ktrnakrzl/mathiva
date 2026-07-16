/// Contract for asking the AI math tutor a question and getting back an
/// answer. `ApiTutorRepository` hits the real backend; `MockTutorRepository`
/// returns canned data so the UI can be developed/demoed without a backend.
abstract class TutorRepository {
  /// Sends [question] to the tutor and streams the answer back as incremental
  /// text chunks — concatenate them to build the full answer. Streaming lets
  /// the chat UI render the reply as it arrives instead of waiting for the
  /// whole thing (the useful answer lands in the first tokens).
  Stream<String> ask(String question);
}
