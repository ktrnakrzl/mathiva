import 'package:flutter/material.dart';
import '../presentation/widgets/atmosphere_background.dart';
import '../presentation/widgets/primary_button.dart';
import '../presentation/widgets/ghost_button.dart';
import '../presentation/widgets/tap_scale.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

// Shared tokens — identical values to HomeScreen's palette, so this screen
// reads as the same surface system rather than its own design.
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);

class ResultScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;
  final String difficulty;
  final String? selectedAnswer;
  final int? elapsedSeconds;
  final bool? isCorrect;

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
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final secondary = AppPreferences.palette.value.secondary;

    final concept = LocalContentService().getConcept(subjectId, topicId, lessonId, conceptId);
    final problem = concept.problem;
    final correct = isCorrect ?? selectedAnswer == problem.answer;
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
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _HeaderIconAction(
              icon: Icons.chat_bubble_outline_rounded,
              tooltip: 'Ask Math Tutor',
              onTap: () => context.push(RouteNames.chat),
              primary: primary,
            ),
          ),
        ],
      ),
      body: AtmosphereBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 86, 20, 28),
            physics: const BouncingScrollPhysics(),
            children: [
              _SoftCard(
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
                      style: const TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Completed in ${_formatElapsed(elapsedSeconds ?? 0)} • $difficulty',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SoftCard(
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
                          child: Icon(Icons.task_alt_rounded, color: primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Correct Answer',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      problem.answer,
                      style: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    if (selectedAnswer != null) ...[
                      const SizedBox(height: 12),
                      Text('Your answer: $selectedAnswer', style: const TextStyle(color: _ink)),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      correct
                          ? 'Why: your choice matches the result from the simplified steps below.'
                          : 'Why: compare your answer with the steps below to see where the result changes.',
                      style: const TextStyle(color: _muted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Step-by-Step Explanation',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              ...problem.steps.asMap().entries.map(
                    (entry) => _StepCard(
                      number: entry.key + 1,
                      text: entry.value,
                    ),
                  ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'View Progress',
                onPressed: () => context.push(
                  RouteNames.conceptProgress,
                  extra: {'subjectId': subjectId, 'topicId': topicId, 'lessonId': lessonId},
                ),
              ),
              const SizedBox(height: 12),
              GhostButton(
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
              GhostButton(label: 'Back Home', onPressed: () => context.go(RouteNames.home)),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SoftCard(
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
                style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(color: _ink, height: 1.5)),
                  const SizedBox(height: 8),
                  const Text(
                    'This step keeps the equation equivalent, so the final answer stays valid.',
                    style: TextStyle(color: _muted, fontSize: 12.5, height: 1.35),
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

// ── Header Icon Action ────────────────────────────────────────────────────────

class _HeaderIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color primary;

  const _HeaderIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 19),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _formatElapsed(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes}m ${remainder}s';
}