import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva_flutter/core/theme/app_theme.dart';
import 'package:mathiva_flutter/presentation/state/auth_notifier.dart';
import 'package:mathiva_flutter/presentation/state/tutor_notifier.dart';
import 'package:mathiva_flutter/presentation/widgets/common_widgets.dart';
import 'package:mathiva_flutter/presentation/widgets/math_renderer.dart';
import '../../../widgets/mathiva_app_bar.dart';

class TutorChatScreen extends ConsumerStatefulWidget {
  final String? topicId;
  final String? questionId;

  const TutorChatScreen({
    Key? key,
    this.topicId,
    this.questionId,
  }) : super(key: key);

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _initializeSession();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeSession() async {
    final user = ref.read(authNotifierProvider).value;
    if (user != null) {
      await ref.read(tutorNotifierProvider.notifier).createSession(
            user.userId,
            topicId: widget.topicId,
            questionId: widget.questionId,
          );
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() => _isLoading = true);

    final session = ref.read(tutorNotifierProvider).value;
    if (session != null) {
      await ref
          .read(tutorNotifierProvider.notifier)
          .sendMessage(session.sessionId, message);

      _scrollToBottom();
    }

    setState(() => _isLoading = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(tutorNotifierProvider);

    return Scaffold(
      appBar: MathivaAppBar(
        title: 'Math Tutor ✨',
        subtitle: 'Ask me anything',
        icon: Icons.smart_toy_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: sessionAsync.when(
        loading: () => const LoadingSpinner(message: 'Starting tutor session...'),
        error: (error, st) => ErrorWidget(
          message: 'Failed to load tutor: $error',
          onRetry: () {
            _initializeSession();
          },
        ),
        data: (session) {
          return Column(
            children: [
              // Chat Messages
              Expanded(
                child: session.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation with your tutor',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: session.messages.length,
                        itemBuilder: (context, index) {
                          final message = session.messages[index];
                          final isUser =
                              message.sender.toString().split('.').last ==
                                  'user';

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppTheme.primaryColor
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: isUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : AppTheme.textPrimaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (message.latexFormula != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: InlineMath(
                                        latex: message.latexFormula!,
                                        fontSize: 14,
                                        color: isUser
                                            ? Colors.white
                                            : AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                  if (message.references != null &&
                                      message.references!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sources: ${message.references!.join(', ')}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isUser
                                            ? Colors.white70
                                            : Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        enabled: !_isLoading,
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      onPressed:
                          _isLoading ? null : _sendMessage,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
