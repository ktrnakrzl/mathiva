import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/presentation/notifiers/quiz_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizNotifierProvider);
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Quiz Result',
        subtitle: 'Your final score',
        icon: Icons.emoji_events_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: state.when(
            data: (quizState) {
              final result = quizState.result;
              if (result == null)
                return const Center(child: Text('Finish a quiz first.'));
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FadeSlideIn(
                    child: _SoftCard(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  palette.primary,
                                  palette.secondary
                                ]),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFF7F9FC), size: 44),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                                  colors: [palette.primary, palette.secondary])
                              .createShader(bounds),
                          child: Text('${result.score}/${result.total}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 8),
                        Text(result.passed ? 'Passed' : 'Needs more practice',
                            style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Points earned: ${result.points_earned}',
                            style: const TextStyle(color: _muted)),
                      ]),
                    ),
                  ),
                ),
              );
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC).withOpacity(.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))
          ],
        ),
        child: child,
      );
}
