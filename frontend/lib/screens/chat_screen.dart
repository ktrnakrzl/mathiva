import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/mathiva_bottom_nav.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Welcome to Mathiva Chat! Ask me anything about math or your lessons.',
      isUser: false,
    ),
  ];
  bool _isSending = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
  final question = _questionController.text.trim();
  if (question.isEmpty || _isSending) return;

  setState(() {
    _messages.add(_ChatMessage(text: question, isUser: true));
    _isSending = true;
    _questionController.clear();
  });

  try {
    final dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    final response = await dio.post(
      '/ask',
      queryParameters: {'question': question},
    );

    final fullAnswer = response.data['answer']?.toString() ?? 'Sorry, I could not get an answer.';
    
    // Add empty message first
    setState(() {
      _messages.add(const _ChatMessage(text: '', isUser: false));
    });

    // Typing animation
    for (int i = 0; i < fullAnswer.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      setState(() {
        _messages.last = _ChatMessage(
          text: fullAnswer.substring(0, i + 1),
          isUser: false,
        );
      });
    }
  } catch (error) {
    setState(() {
      _messages.add(_ChatMessage(
        text: 'Error: ${error.toString()}',
        isUser: false,
      ));
    });
  } finally {
    setState(() {
      _isSending = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppPreferences.palette.value.background,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppPreferences.palette.value.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ask math questions, get help, and explore concepts in a friendly chat view.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6D6978),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.86),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(.95)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return _ChatBubble(
                                text: message.text,
                                isUser: message.isUser,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _questionController,
                                onSubmitted: (_) => _sendQuestion(),
                                enabled: !_isSending,
                                decoration: InputDecoration(
                                  hintText: 'Type your math question...',
                                  filled: true,
                                  fillColor: AppPreferences
                                      .palette.value.background.first
                                      .withOpacity(.22),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppPreferences.palette.value.primary,
                              ),
                              child: IconButton(
                                onPressed: _isSending ? null : _sendQuestion,
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.chat),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isUser ? AppPreferences.palette.value.primary : Colors.white;
    final textColor = isUser ? Colors.white : AppColors.ink;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 24),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.45),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}