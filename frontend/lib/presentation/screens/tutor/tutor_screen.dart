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
import 'package:mathiva/presentation/widgets/glass_card.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/services/app_preferences.dart';
import 'package:mathiva/theme/app_theme.dart';
import '../../../widgets/mathiva_app_bar.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _questionController =
      TextEditingController(text: 'Is f(x)=2x+1 a function?');

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutorState = ref.watch(tutorNotifierProvider);
    final palette = AppPreferences.palette.value;
    final colors = AppTheme.colorsOf(context);
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
        vivid: true,
        child: SafeArea(
          top: false,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              physics: const BouncingScrollPhysics(),
              children: [
                const SectionHeader(
                  title: 'Ask Anything',
                  subtitle: 'Your AI math companion',
                ),
                FadeSlideIn(
                  child: GlassCard(
                    child: Column(children: [
                      TextField(
                        controller: _questionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Ask a math question…',
                          filled: true,
                          fillColor: palette.primary.withOpacity(.08),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: palette.primary, width: 1.6)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GradientButton(
                          label: 'Ask Tutor',
                          onPressed: () => ref
                              .read(tutorNotifierProvider.notifier)
                              .askQuestion(_questionController.text, 'gen_math',
                                  'gen_math_functions')),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                tutorState.when(
                  data: (response) => response == null
                      ? FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: GlassCard(
                              child: Text(AppStrings.askPrompt,
                                  style: TextStyle(color: colors.muted))),
                        )
                      : FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: GlassCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        palette.primary.withOpacity(.14),
                                        palette.secondary.withOpacity(.14)
                                      ]),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(response.difficulty,
                                        style: TextStyle(
                                            color: palette.primary,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(height: 12),
                                  MathRenderer(
                                      text: response.answer,
                                      textStyle: TextStyle(
                                          color: colors.ink, height: 1.4),
                                      mathFontSize: 16),
                                  const SizedBox(height: 12),
                                  StepRevealer(steps: response.steps),
                                  const SizedBox(height: 12),
                                  Text(
                                      'Source: ${response.source_chunks.join(', ')}',
                                      style: TextStyle(
                                          color: colors.muted, fontSize: 12)),
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
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: palette.primary,
            side: BorderSide(color: palette.primary, width: 1),
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
