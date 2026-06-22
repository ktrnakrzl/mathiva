import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/core/utils/math_renderer.dart';
import 'package:mathiva/presentation/notifiers/tutor_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/step_revealer.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _questionController = TextEditingController(text: 'Is f(x)=2x+1 a function?');

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutorState = ref.watch(tutorNotifierProvider);
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MathivaAppBar(
        title: 'Math Tutor ✨',
        subtitle: 'AI-powered math help',
        icon: Icons.smart_toy_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), physics: const BouncingScrollPhysics(), children: [
            const SectionHeader(
              title: 'Ask Anything',
              subtitle: 'Your AI math companion',
            ),
            FadeSlideIn(
              child: _SoftCard(
                child: Column(children: [
                  TextField(
                    controller: _questionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ask a math question…',
                      filled: true,
                      fillColor: palette.primary.withOpacity(.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.primary, width: 1.6)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GradientButton(label: 'Ask Tutor', onPressed: () => ref.read(tutorNotifierProvider.notifier).askQuestion(_questionController.text, 'gen_math', 'gen_math_functions')),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            tutorState.when(
              data: (response) => response == null
                  ? FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: _SoftCard(child: Text(AppStrings.askPrompt, style: const TextStyle(color: _muted))),
                    )
                  : FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: _SoftCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [palette.primary.withOpacity(.14), palette.secondary.withOpacity(.14)]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(response.difficulty, style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(height: 12),
                          MathRenderer(text: response.answer, textStyle: const TextStyle(color: _ink, height: 1.4), mathFontSize: 16),
                          const SizedBox(height: 12),
                          StepRevealer(steps: response.steps),
                          const SizedBox(height: 12),
                          Text('Source: ${response.source_chunks.join(', ')}', style: const TextStyle(color: _muted, fontSize: 12)),
                        ]),
                      ),
                    ),
              loading: () => const LoadingOverlay(),
              error: (error, _) => Text('Error: $error'),
            ),
          ]),
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
    final palette = AppPreferences.palette.value;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [palette.primary, palette.secondary]), borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: const Color(0xFFF7F9FC), shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
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
