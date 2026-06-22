import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/presentation/notifiers/quiz_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/step_revealer.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);

class AnswerFeedbackScreen extends ConsumerWidget {
  const AnswerFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizNotifierProvider);
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Answer Feedback',
        subtitle: 'See how you did',
        icon: Icons.fact_check_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: state.when(
            data: (quizState) {
              final answer = quizState.lastAnswer;
              if (answer == null) return const Center(child: Text('Submit an answer first.'));
              return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), physics: const BouncingScrollPhysics(), children: [
                FadeSlideIn(
                  child: _SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: answer.is_correct ? [palette.primary, palette.secondary] : [palette.secondary, palette.primary]),
                        ),
                        child: Icon(answer.is_correct ? Icons.check_rounded : Icons.refresh_rounded, color: const Color(0xFFF7F9FC), size: 34),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(colors: [palette.primary, palette.secondary]).createShader(bounds),
                      child: Text(
                        answer.is_correct ? 'Correct!' : 'Review this item.',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Correct answer: ${answer.correct_answer}', style: const TextStyle(color: _muted)),
                    const SizedBox(height: 18),
                    StepRevealer(steps: answer.solution_steps),
                  ])),
                ),
              ]);
            },
            loading: () => const LoadingOverlay(),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC).withOpacity(.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: child,
      );
}
