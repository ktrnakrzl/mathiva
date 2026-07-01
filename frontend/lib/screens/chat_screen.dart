import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/math_renderer.dart';
import '../presentation/widgets/animated_background.dart';
import '../services/app_preferences.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';

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

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _typingController;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hi! I\'m your Mathivia tutor. Ask me to solve, explain, or check any math problem. I\'ll include the steps and why each step works.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    String answer;
    try {
      // Calls the real backend (/api/ask, RAG + Phi-3) via the repository
      // pattern's swappable facade — see lib/repositories/tutor_repository.dart.
      answer = await ChatService.ask(question);
    } catch (_) {
      // Surface a real failure instead of silently faking a plausible-looking
      // answer — a previous version of this screen did that and it read as
      // the tutor "hallucinating" when the request had actually failed.
      answer = 'Sorry, I couldn\'t reach the tutor right now. Please check '
          'your connection and try again.';
    }

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: answer,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _useSuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.pageBg,
      appBar: const MathivaTopBar(),
      bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.tutor),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _ChatHeader(primary: primary),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _TypingBubble(
                          controller: _typingController, primary: primary);
                    }
                    return _ChatBubble(
                        message: _messages[index], primary: primary);
                  },
                ),
              ),
              _InputBar(
                controller: _controller,
                enabled: !_isTyping,
                primary: primary,
                onSend: _sendMessage,
                onSuggestionTap: _useSuggestion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── In-body header (tutor identity + status) ────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final Color primary;
  const _ChatHeader({required this.primary});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: colors.pageBg,
        border: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.ring,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.smart_toy_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Math Tutor',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Online · Ready to help',
                    style: TextStyle(
                      color: colors.subtleMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Color primary;

  const _ChatBubble({required this.message, required this.primary});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colors = AppTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _Avatar(primary: primary),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * .74,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: isUser ? primary : colors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isUser ? 18 : 4),
                    topRight: const Radius.circular(18),
                    bottomLeft: const Radius.circular(18),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border:
                      isUser ? null : Border.all(color: colors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? primary.withOpacity(0.12)
                          : const Color(0x08000000),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MathRenderer(
                  text: message.text,
                  mathFontSize: 14,
                  textStyle: TextStyle(
                    color: isUser ? Colors.white : colors.ink,
                    height: 1.5,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Typing Bubble ─────────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  final AnimationController controller;
  final Color primary;

  const _TypingBubble({required this.controller, required this.primary});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(primary: primary),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: colors.border, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    final value = (controller.value + index * .18) % 1;
                    final offset = value < .5 ? -5 * value : -5 * (1 - value);
                    return Transform.translate(
                        offset: Offset(0, offset), child: child);
                  },
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Color primary;
  const _Avatar({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Icon(Icons.smart_toy_rounded, color: primary, size: 14),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final Color primary;
  final VoidCallback onSend;
  final ValueChanged<String> onSuggestionTap;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.primary,
    required this.onSend,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    const suggestions = [
      'Solve quadratic?',
      'Explain derivatives',
      'What is integration?',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => onSuggestionTap(suggestions[index]),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withOpacity(0.15)),
                  ),
                  child: Text(
                    suggestions[index],
                    style: TextStyle(
                      color: primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: TextStyle(color: colors.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask a math question…',
                    hintStyle: TextStyle(color: colors.muted, fontSize: 14),
                    filled: true,
                    fillColor: colors.pageBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                height: 44,
                child: OutlinedButton(
                  onPressed: enabled ? onSend : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: primary,
                    disabledForegroundColor: colors.border,
                    side: BorderSide(
                        color: enabled ? primary : colors.border, width: 1),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatTime(DateTime value) {
  final hour =
      value.hour > 12 ? value.hour - 12 : (value.hour == 0 ? 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
