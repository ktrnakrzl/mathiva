import 'package:flutter/material.dart';
import '../core/utils/math_renderer.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/glass_card.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../data/local_mathiva_data.dart';
import '../models/mathiva_models.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

class SolutionScreen extends StatelessWidget {
  final PracticeProblem? problem;

  const SolutionScreen({super.key, this.problem});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);
    final problem = this.problem ?? LocalMathivaData.quadraticProblem;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Solution',
        subtitle: 'Step-by-step breakdown',
        icon: Icons.lightbulb_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
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
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(
                'Detected Equation',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: Center(
                  child: MathRenderer(
                    text: problem.question.replaceAll('Solve for x: ', ''),
                    mathFontSize: 28,
                    textStyle: TextStyle(
                      color: primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Step-by-Step',
                style: TextStyle(
                  color: colors.ink,
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
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Final Answer',
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
                    MathRenderer(
                      text: problem.answer,
                      mathFontSize: 26,
                      textStyle: TextStyle(
                        color: primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _GradientButton(
                label: 'Practice Similar Problem',
                onPressed: () => context.push(RouteNames.subjects),
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.only(bottom: 14),
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
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MathRenderer(
                    text: text,
                    textStyle: TextStyle(color: colors.ink, height: 1.5),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
