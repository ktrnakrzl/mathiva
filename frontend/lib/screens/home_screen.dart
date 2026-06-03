import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/local_mathiva_data.dart';
import '../models/mathiva_models.dart';
import '../theme/app_theme.dart';
import '../services/app_preferences.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))..forward();
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppPreferences.palette.value.background,
          ),
        ),
        child: SizedBox.expand(
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
                physics: const BouncingScrollPhysics(),
                children: [
                  _AnimatedIn(animation: _entranceController, intervalStart: 0.00, child: const _Header()),
                  const SizedBox(height: 18),
                  _AnimatedIn(animation: _entranceController, intervalStart: 0.08, child: const _DailyMissionCard()),
                  const SizedBox(height: 18),
                  _AnimatedIn(
                    animation: _entranceController,
                    intervalStart: 0.16,
                    child: _SearchPill(onTap: () => Navigator.pushNamed(context, RouteNames.search)),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedIn(animation: _entranceController, intervalStart: 0.28, child: const _SectionTitle()),
                  const SizedBox(height: 14),
                  for (int index = 0; index < LocalMathivaData.subjects.length; index++) ...[
                    _AnimatedIn(
                      animation: _entranceController,
                      intervalStart: 0.34 + (index * .08),
                      child: _SubjectCard(
                        subject: LocalMathivaData.subjects[index],
                        accent: _subjectAccents[index],
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.lessons,
                          arguments: {'subjectId': LocalMathivaData.subjects[index].id},
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 28,
              bottom: 138,
              child: _AnimatedIn(
                animation: _entranceController,
                intervalStart: 0.68,
                child: _ImageSolverButton(onTap: () => Navigator.pushNamed(context, RouteNames.imageSolver)),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.home),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity( .55),
            borderRadius: BorderRadius.circular(20),
                      ),
          child: const Center(child: Text('👋', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: AppPreferences.studentName,
                builder: (context, name, _) {
                  final displayName = name.trim().isEmpty ? 'Learner' : name.trim();
                  return Text(
                    'Hello, $displayName!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 29, height: 1.05, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -.6),
                  );
                },
              ),
              const SizedBox(height: 6),
              const Text(
                'Ready for another math win?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, RouteNames.profile),
          child: Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.white, AppPreferences.palette.value.background.last]),
                          ),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppPreferences.palette.value.primary.withOpacity(.12)),
              child: Icon(Icons.person_rounded, color: AppPreferences.palette.value.primary, size: 34),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: [Colors.white.withOpacity( .92), Colors.white.withOpacity( .70)]),
        border: Border.all(color: Colors.white.withOpacity( .95)),
              ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: .72,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppPreferences.palette.value.primary.withOpacity(.12),
                  valueColor: AlwaysStoppedAnimation(AppPreferences.palette.value.primary),
                ),
              ),
              const Text('72%', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily mission', style: TextStyle(fontSize: 18, color: AppColors.ink, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Finish one lesson and one short quiz today.', style: TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.35)),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppPreferences.palette.value.secondary.withOpacity(.14), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.bolt_rounded, color: AppPreferences.palette.value.secondary),
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity( .86),
            borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity( .90)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF4A465C), size: 30),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Search topics, lessons, formulas...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF9B96A8), fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Icon(Icons.tune_rounded, color: AppPreferences.palette.value.primary, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickAction(icon: Icons.menu_book_rounded, label: 'Lessons', color: AppPreferences.palette.value.primary, onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(icon: Icons.task_alt_rounded, label: 'Practice', color: AppPreferences.palette.value.secondary, onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(icon: Icons.document_scanner_rounded, label: 'Scan', color: AppPreferences.palette.value.primary, onTap: () => Navigator.pushNamed(context, RouteNames.imageSolver))),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity( .70),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity( .9)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text('Math Subjects', style: TextStyle(fontSize: 20, color: AppColors.ink, fontWeight: FontWeight.w900)),
        Spacer(),
        Text('4 courses', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final MathSubject subject;
  final _SubjectAccent accent;
  final VoidCallback onTap;

  const _SubjectCard({required this.subject, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity( .92),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity( .96)),
                      ),
          child: Row(
            children: [
              _SubjectIcon(accent: accent),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.ink, fontSize: 18, height: 1.15, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      accent.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(color: AppPreferences.palette.value.primary.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Start', style: TextStyle(color: AppPreferences.palette.value.primary, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: AppPreferences.palette.value.primary, size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectIcon extends StatelessWidget {
  final _SubjectAccent accent;

  const _SubjectIcon({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPreferences.palette.value.primary.withOpacity(.12), Colors.white.withOpacity( .8)]),
        borderRadius: BorderRadius.circular(24),
              ),
      child: Stack(
        children: [
          Positioned(right: 9, top: 8, child: Icon(Icons.auto_awesome_rounded, color: AppPreferences.palette.value.primary.withOpacity( .18), size: 17)),
          Center(child: Icon(accent.icon, color: AppPreferences.palette.value.primary, size: 38)),
        ],
      ),
    );
  }
}

class _ImageSolverButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ImageSolverButton({required this.onTap});

  @override
  State<_ImageSolverButton> createState() => _ImageSolverButtonState();
}

class _ImageSolverButtonState extends State<_ImageSolverButton> with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final dy = math.sin(_floatController.value * math.pi) * -6;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPreferences.palette.value.secondary, AppPreferences.palette.value.primary]),
                      ),
          child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 42),
        ),
      ),
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  final Animation<double> animation;
  final double intervalStart;
  final Widget child;

  const _AnimatedIn({required this.animation, required this.intervalStart, required this.child});

  @override
  Widget build(BuildContext context) {
    // Keep this wrapper so existing UI code stays unchanged, but avoid Opacity,
    // Transform and animated layers because they triggered rendering artifacts
    // on some Android tablets.
    return child;
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity( .20),
          ),
        ),
      ),
    );
  }
}

class _DotPattern extends StatelessWidget {
  const _DotPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: .50,
        child: SizedBox(
          width: 88,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              24,
              (_) => Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _OrbitDot({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(math.cos(controller.value * math.pi * 2) * 12, math.sin(controller.value * math.pi * 2) * 12),
      child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withOpacity( .7), shape: BoxShape.circle)),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final AnimationController controller;

  const _Sparkle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scale = .75 + (math.sin(controller.value * math.pi * 2) + 1) * .18;
    return Transform.scale(scale: scale, child: Icon(Icons.auto_awesome_rounded, color: AppPreferences.palette.value.secondary, size: 22));
  }
}

class _SubjectAccent {
  final IconData icon;
  final Color primary;
  final Color soft;
  final String description;

  const _SubjectAccent({required this.icon, required this.primary, required this.soft, required this.description});
}

final _subjectAccents = [
  _SubjectAccent(icon: Icons.functions_rounded, primary: AppPreferences.palette.value.primary, soft: AppPreferences.palette.value.background.last, description: 'Build strong foundations in everyday math.'),
  _SubjectAccent(icon: Icons.bar_chart_rounded, primary: AppPreferences.palette.value.primary, soft: AppPreferences.palette.value.background.last, description: 'Explore data, variability, and chance.'),
  _SubjectAccent(icon: Icons.show_chart_rounded, primary: AppPreferences.palette.value.primary, soft: AppPreferences.palette.value.background.last, description: 'Prepare for advanced math concepts.'),
  _SubjectAccent(icon: Icons.integration_instructions_rounded, primary: AppPreferences.palette.value.primary, soft: AppPreferences.palette.value.background.last, description: 'Differentiate, integrate, and understand change.'),
];
