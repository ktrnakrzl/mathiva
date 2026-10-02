/// A conversation turn sent as context to the tutor.
class TutorChatTurn {
  final String role;
  final String text;

  const TutorChatTurn({
    required this.role,
    required this.text,
  });
}

/// Contract for asking the backend tutor a question and streaming its answer.
abstract class TutorRepository {
  /// Sends [question] to the tutor and streams the answer back as incremental
  /// text chunks; concatenate them to build the full answer. Streaming lets the
  /// chat UI render the reply as it arrives instead of waiting for the whole
  /// thing.
  Stream<String> ask(
    String question, {
    List<TutorChatTurn> history = const [],
  });
}
