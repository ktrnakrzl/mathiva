import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/utils/math_renderer.dart';
import 'package:mathiva/presentation/notifiers/quiz_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(quizNotifierProvider.notifier).startQuiz('gen_math', 'gen_math_functions', 'Easy'));
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Quiz',
        subtitle: 'Test your knowledge',
        icon: Icons.quiz_rounded,
        showBack: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: quizState.when(
            data: (state) {
              final quiz = state.quiz;
              if (quiz == null) return const Center(child: Text('No quiz loaded.'));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: quiz.questions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const SectionHeader(
                      title: 'Quiz',
                      subtitle: 'Answer each question carefully',
                    );
                  }
                  final question = quiz.questions[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 60 * index),
                      child: _SoftCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Pill(label: 'Question $index', palette: palette),
                          const SizedBox(height: 14),
                          MathRenderer(text: question.question_text, textStyle: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800), mathFontSize: 18),
                          const SizedBox(height: 14),
                          ...question.choices.map((choice) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _ChoiceButton(label: choice, onPressed: () => ref.read(quizNotifierProvider.notifier).submitAnswer(quiz.quiz_id, question.question_id, choice)))),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingOverlay(),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [palette.primary, palette.secondary]), borderRadius: BorderRadius.circular(14)),
        child: FloatingActionButton.extended(
          onPressed: () => ref.read(quizNotifierProvider.notifier).finishQuiz('quiz_001'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFFF7F9FC),
          label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.w900)),
          icon: const Icon(Icons.check_rounded),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final MathiviaPalette palette;
  const _Pill({required this.label, required this.palette});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [palette.primary.withOpacity(.14), palette.secondary.withOpacity(.14)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800)),
      );
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _ChoiceButton({required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFF7F9FC), foregroundColor: _ink, side: const BorderSide(color: Color(0xFFEDE9FF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.all(16), alignment: Alignment.centerLeft),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
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
