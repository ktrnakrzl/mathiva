import 'package:flutter/material.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/glass_card.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/duration_format.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

class ResultScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;
  final String difficulty;
  final String? selectedAnswer;
  final int? elapsedSeconds;
  final bool? isCorrect;
  // The correct answer and worked steps as graded by the server
  // (POST /api/quiz/answer). Optional so the screen still renders if reached
  // without them; falls back to the local content's static problem.
  final String? correctAnswer;
  final List<String>? steps;

  const ResultScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
    required this.conceptId,
    required this.difficulty,
    this.selectedAnswer,
    this.elapsedSeconds,
    this.isCorrect,
    this.correctAnswer,
    this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final secondary = AppPreferences.palette.value.secondary;
    final colors = AppTheme.colorsOf(context);

    // Prefer the server-graded answer/steps; fall back to the local static
    // problem only if this screen was reached without them.
    final problem = LocalContentService()
        .getConcept(subjectId, topicId, lessonId, conceptId)
        .problem;
    final answer = correctAnswer ?? problem.answer;
    final resolvedSteps = steps ?? problem.steps;
    final correct = isCorrect ?? selectedAnswer == answer;
    final resultColor = correct ? primary : secondary;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Skip practice screen — go back to concept/difficulty selection.
        if (context.canPop()) context.pop(); // pop result
        if (context.canPop()) context.pop(); // pop practice
        if (!context.canPop()) context.go(RouteNames.home);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: MathivaAppBar(
          title: 'Answer Feedback',
          subtitle: 'See how you did',
          icon: Icons.fact_check_rounded,
          onBack: () {
            // Skip practice screen — go back to concept/difficulty selection.
            if (context.canPop()) context.pop(); // pop result
            if (context.canPop()) context.pop(); // pop practice
            if (!context.canPop()) context.go(RouteNames.home);
          },
          actions: [
            IconButton(
              tooltip: 'Ask Math Tutor',
              onPressed: () => context.push(RouteNames.chat),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              color: primary,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: AnimatedBackground(
          vivid: true,
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 86, 20, 28),
              physics: const BouncingScrollPhysics(),
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          correct ? Icons.check_rounded : Icons.close_rounded,
                          color: resultColor,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        correct ? 'Great job!' : 'Keep practicing!',
                        style: TextStyle(
                            color: colors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Completed in ${formatElapsed(elapsedSeconds ?? 0)} • $difficulty',
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(Icons.task_alt_rounded,
                                color: primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Correct Answer',
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        answer,
                        style: TextStyle(
                            color: primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                      if (selectedAnswer != null) ...[
                        const SizedBox(height: 12),
                        Text('Your answer: $selectedAnswer',
                            style: TextStyle(color: colors.ink)),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        correct
                            ? 'Why: your choice matches the result from the simplified steps below.'
                            : 'Why: compare your answer with the steps below to see where the result changes.',
                        style: TextStyle(color: colors.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Step-by-Step Explanation',
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                ...resolvedSteps.asMap().entries.map(
                      (entry) => _StepCard(
                        number: entry.key + 1,
                        text: entry.value,
                      ),
                    ),
                const SizedBox(height: 10),
                _GradientButton(
                  label: 'View Progress',
                  onPressed: () => context.push(
                    RouteNames.conceptProgress,
                    extra: {
                      'subjectId': subjectId,
                      'topicId': topicId,
                      'lessonId': lessonId,
                      'conceptId': conceptId,
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _OutlineButton(
                  label: 'Try Again',
                  onPressed: () => context.push(
                    RouteNames.practice,
                    extra: {
                      'subjectId': subjectId,
                      'topicId': topicId,
                      'lessonId': lessonId,
                      'conceptId': conceptId,
                      'difficulty': difficulty,
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _OutlineButton(
                    label: 'Back Home',
                    onPressed: () => context.go(RouteNames.home)),
              ],
            ),
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String text;

  const _StepCard({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    final colors = AppTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$number',
                style: TextStyle(
                    color: primary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: TextStyle(color: colors.ink, height: 1.5)),
                  const SizedBox(height: 8),
                  Text(
                    'This step keeps the equation equivalent, so the final answer stays valid.',
                    style: TextStyle(
                        color: colors.muted, fontSize: 12.5, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: primary,
          side: BorderSide(color: colors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
