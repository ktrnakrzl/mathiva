import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva_flutter/core/theme/app_theme.dart';
import 'package:mathiva_flutter/presentation/state/auth_notifier.dart';
import 'package:mathiva_flutter/presentation/state/quiz_notifier.dart';
import 'package:mathiva_flutter/presentation/state/subject_notifier.dart';
import '../../../widgets/mathiva_app_bar.dart';

class QuizStartScreen extends ConsumerStatefulWidget {
  final String topicId;

  const QuizStartScreen({
    Key? key,
    required this.topicId,
  }) : super(key: key);

  @override
  ConsumerState<QuizStartScreen> createState() => _QuizStartScreenState();
}

class _QuizStartScreenState extends ConsumerState<QuizStartScreen> {
  int _numQuestions = 5;
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final topicAsync = ref.watch(topicByIdProvider(widget.topicId));
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: MathivaAppBar(
        title: 'Start Quiz',
        subtitle: 'Ready when you are',
        icon: Icons.play_circle_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: topicAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Text('Failed to load topic: $error'),
        ),
        data: (topic) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Setup',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                // Topic Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mastery Level',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${topic.masteryPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Questions Attempted',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${topic.questionsAttempted}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Number of Questions Selector
                Text(
                  'Number of Questions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [5, 10, 15]
                            .map((num) => GestureDetector(
                              onTap: () {
                                setState(() => _numQuestions = num);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _numQuestions == num
                                      ? AppTheme.primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '$num',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _numQuestions == num
                                          ? Colors.white
                                          : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isStarting
                        ? null
                        : () async {
                            final user = userAsync.value;
                            if (user == null) return;

                            setState(() => _isStarting = true);

                            await ref
                                .read(quizNotifierProvider.notifier)
                                .createSession(
                                  user.userId,
                                  widget.topicId,
                                  _numQuestions,
                                );

                            if (!mounted) return;
                            setState(() => _isStarting = false);

                            ref.listen(quizNotifierProvider, (previous, next) {
                              next.whenData((session) {
                                context.push(
                                  '/quiz/${widget.topicId}/session/${session.sessionId}',
                                );
                              });
                            });
                          },
                    child: _isStarting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Start Quiz',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
