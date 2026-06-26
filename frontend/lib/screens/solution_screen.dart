import 'package:flutter/material.dart';
import '../presentation/widgets/atmosphere_background.dart';
import '../presentation/widgets/primary_button.dart';
import '../presentation/widgets/tap_scale.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../data/local_mathiva_data.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

// Shared tokens — identical values to HomeScreen's palette, so this screen
// reads as the same surface system rather than its own design.
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);

class SolutionScreen extends StatelessWidget {
  const SolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final problem = LocalMathivaData.quadraticProblem;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Solution',
        subtitle: 'Step-by-step breakdown',
        icon: Icons.lightbulb_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
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
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(
                'Detected Equation',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              _SoftCard(
                child: Center(
                  child: Text(
                    problem.question.replaceAll('Solve for x: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                      style: TextStyle(
                        color: primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                  Text(
                    text,
                    style: const TextStyle(color: _ink, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Why: this step moves closer to the answer while keeping the equation balanced.',
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