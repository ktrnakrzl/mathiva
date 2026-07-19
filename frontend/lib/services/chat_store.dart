import 'package:flutter/foundation.dart';

/// A single message in the tutor chat.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Holds the tutor conversation for the whole app session.
///
/// The Ask tab is a go_router route, so leaving it and coming back rebuilds
/// ChatScreen from scratch — which would reset any state kept inside the widget.
/// Keeping the messages here (matching the AppPreferences singleton idiom) lets
/// the conversation survive navigation. ChatScreen mutates this same list in
/// place, so history persists without copying.
class ChatStore {
  ChatStore._();

  static final ValueNotifier<List<ChatMessage>> messages =
      ValueNotifier<List<ChatMessage>>([
    ChatMessage(
      text:
          'Hi! I\'m your Mathivia tutor. Ask me to solve, explain, or check any math problem. I\'ll include the steps and why each step works.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  /// Clear the conversation back to just the welcome message (for a future
  /// "new chat" action).
  static void reset() {
    messages.value = [
      ChatMessage(
        text:
            'Hi! I\'m your Mathivia tutor. Ask me to solve, explain, or check any math problem. I\'ll include the steps and why each step works.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}
