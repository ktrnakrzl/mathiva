import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/core/theme/app_theme.dart';
import 'package:mathiva/presentation/state/quiz_notifier.dart';
import 'package:mathiva/presentation/widgets/common_widgets.dart';
import 'package:mathiva/presentation/widgets/math_renderer.dart';
import '../../../widgets/mathiva_app_bar.dart';

class QuizQuestionScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String sessionId;

  const QuizQuestionScreen({
    Key? key,
    required this.topicId,
    required this.sessionId,
  }) : super(key: key);

  @override
  ConsumerState<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends ConsumerState<QuizQuestionScreen> {
  String? _selectedAnswer;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(quizSessionProvider(widget.sessionId));

    return Scaffold(
      appBar: MathivaAppBar(
        title: 'Quiz',
        subtitle: 'Answer all questions',
        icon: Icons.quiz_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: sessionAsync.when(
        loading: () => const LoadingSpinner(),
        error: (error, st) => ErrorWidget(
          message: 'Failed to load quiz: $error',
          onRetry: () {
            ref.refresh(quizSessionProvider(widget.sessionId));
          },
        ),
        data: (session) {
          final currentQuestion =
              session.questions[session.currentQuestionIndex];
          final progress =
              ((session.currentQuestionIndex + 1) / session.questions.length)
                  .clamp(0.0, 1.0);

          return Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              // Question Counter
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${session.currentQuestionIndex + 1} of ${session.questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DifficultyBadge(
                      difficulty:
                          currentQuestion.difficulty.toString().split('.').last,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Text
                      Text(
                        currentQuestion.questionText,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      // LaTeX Formula if present
                      if (currentQuestion.latexFormula != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: double.infinity,
                          child: MathRenderer(
                            latex: currentQuestion.latexFormula!,
                            fontSize: 20,
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Answer Options
                      Text(
                        'Choose your answer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...currentQuestion.options.map((option) {
                        final isSelected = _selectedAnswer == option;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedAnswer = option);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey[400]!,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimaryColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              // Submit Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _selectedAnswer == null || _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);

                            await ref
                                .read(quizNotifierProvider.notifier)
                                .submitAnswer(
                                  widget.sessionId,
                                  session.currentQuestionIndex,
                                  _selectedAnswer!,
                                );

                            if (!mounted) return;
                            setState(() => _isSubmitting = false);

                            ref.listen(quizNotifierProvider, (previous, next) {
                              next.whenData((updatedSession) {
                                setState(() => _selectedAnswer = null);

                                if (updatedSession.isCompleted) {
                                  context.push(
                                    '/quiz/${widget.topicId}/result/${widget.sessionId}',
                                  );
                                }
                              });
                            });
                          },
                    child: _isSubmitting
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
                        : Text(
                            session.currentQuestionIndex ==
                                    session.questions.length - 1
                                ? 'Finish Quiz'
                                : 'Next Question',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
