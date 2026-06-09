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
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..forward();
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
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
      body: Container(
        color: Colors.white,
        child: SizedBox.expand(
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Existing UI
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _AnimatedIn(
                          animation: _entranceController,
                          intervalStart: 0.00,
                          child: const _Header()),
                      const SizedBox(height: 18),

                      // Quick Actions section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          children: const [
                            Text('Quick Actions',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                            Spacer(),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedIn(
                          animation: _entranceController,
                          intervalStart: 0.06,
                          child: _QuickActions()),
                      const SizedBox(height: 20),

                      // Continue Learning (large pill)
                      _AnimatedIn(
                          animation: _entranceController,
                          intervalStart: 0.14,
                          child: const _ContinueLearningCard()),
                      const SizedBox(height: 20),

                      // Recent Scans header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          children: [
                            const Text('Recent Scans',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {},
                              child: Text('See all',
                                  style: TextStyle(
                                      color:
                                          AppPreferences.palette.value.primary,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedIn(
                          animation: _entranceController,
                          intervalStart: 0.22,
                          child: _RecentScanCard(
                              problem: LocalMathivaData.quadraticProblem)),
                      const SizedBox(height: 12),
                      _AnimatedIn(
                          animation: _entranceController,
                          intervalStart: 0.26,
                          child: _RecentScanCard(
                              problem: LocalMathivaData.quadraticProblem)),

                      const SizedBox(height: 22),
                      _AnimatedIn(
                          animation: _entranceController,
                          intervalStart: 0.34,
                          child: const _SectionTitle()),
                      const SizedBox(height: 14),
                      for (int index = 0;
                          index < LocalMathivaData.subjects.length;
                          index++) ...[
                        _AnimatedIn(
                          animation: _entranceController,
                          intervalStart: 0.40 + (index * .06),
                          child: _SubjectCard(
                            subject: LocalMathivaData.subjects[index],
                            accent: _subjectAccents[index],
                            onTap: () => Navigator.pushNamed(
                              context,
                              RouteNames.lessons,
                              arguments: {
                                'subjectId': LocalMathivaData.subjects[index].id
                              },
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
                    child: _ImageSolverButton(
                        onTap: () => Navigator.pushNamed(
                            context, RouteNames.imageSolver)),
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
            color: Colors.white.withOpacity(.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
              child: Icon(Icons.emoji_emotions_outlined,
                  size: 28,
                  color: Color(0xFF4A465C))), // neutral icon instead of emoji
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: AppPreferences.studentName,
                builder: (context, name, _) {
                  final displayName =
                      name.trim().isEmpty ? 'Learner' : name.trim();
                  return Text(
                    'Hello, $displayName!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      height: 1.05,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              const Text(
                'Ready for another math win?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
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
              gradient: LinearGradient(colors: [
                Colors.white,
                AppPreferences.palette.value.background.last
              ]),
            ),
            child: Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPreferences.palette.value.primary.withOpacity(.12)),
              child: Icon(Icons.person_rounded,
                  color: AppPreferences.palette.value.primary, size: 34),
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
        color: Colors.white.withOpacity(.90),
        border: Border.all(color: Colors.white.withOpacity(.95)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                  backgroundColor:
                      AppPreferences.palette.value.primary.withOpacity(.12),
                  valueColor: AlwaysStoppedAnimation(
                      AppPreferences.palette.value.primary),
                ),
              ),
              const Text('72%',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily mission',
                    style: TextStyle(
                        fontSize: 18,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Finish one lesson and one short quiz today.',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        height: 1.35)),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppPreferences.palette.value.secondary.withOpacity(.14),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.bolt_rounded,
                color: AppPreferences.palette.value.secondary),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [
          AppPreferences.palette.value.primary,
          AppPreferences.palette.value.secondary
        ]),
        boxShadow: [
          BoxShadow(
              color: AppPreferences.palette.value.primary.withOpacity(.18),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Linear Equations',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('12 / 20 Lessons',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
            child: Icon(Icons.arrow_forward_rounded,
                color: AppPreferences.palette.value.primary),
          ),
        ],
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final PracticeProblem problem;

  const _RecentScanCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: AppPreferences.palette.value.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.grid_on_rounded,
                color: AppPreferences.palette.value.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(problem.question,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 6),
                const Text('Solved · Yesterday',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppPreferences.palette.value.primary),
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
            color: Colors.white.withOpacity(.86),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(.90)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: Color(0xFF4A465C), size: 30),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Search topics, lessons, formulas...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF9B96A8),
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
              Icon(Icons.tune_rounded,
                  color: AppPreferences.palette.value.primary, size: 26),
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
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _QuickAction(
            icon: Icons.document_scanner_rounded,
            label: 'Scan',
            color: AppPreferences.palette.value.primary,
            onTap: () => Navigator.pushNamed(context, RouteNames.imageSolver)),
        _QuickAction(
            icon: Icons.menu_book_rounded,
            label: 'Practice',
            color: AppPreferences.palette.value.primary,
            onTap: () {}),
        _QuickAction(
            icon: Icons.bar_chart_rounded,
            label: 'Progress',
            color: AppPreferences.palette.value.primary,
            onTap: () {}),
        _QuickAction(
            icon: Icons.emoji_events_rounded,
            label: 'Awards',
            color: AppPreferences.palette.value.secondary,
            onTap: () {}),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(.95),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color.withOpacity(.10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink)),
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
        Text('Math Subjects',
            style: TextStyle(
                fontSize: 20,
                color: AppColors.ink,
                fontWeight: FontWeight.w900)),
        Spacer(),
        Text('4 courses',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final MathSubject subject;
  final _SubjectAccent accent;
  final VoidCallback onTap;

  const _SubjectCard(
      {required this.subject, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.92),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(.96)),
          ),
          child: Row(
            children: [
              _SubjectIcon(accent: accent),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      accent.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                    color:
                        AppPreferences.palette.value.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Start',
                        style: TextStyle(
                            color: AppPreferences.palette.value.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: AppPreferences.palette.value.primary, size: 22),
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
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppPreferences.palette.value.primary.withOpacity(.12),
              Colors.white.withOpacity(.8)
            ]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
              right: 9,
              top: 8,
              child: Icon(Icons.auto_awesome_rounded,
                  color: AppPreferences.palette.value.primary.withOpacity(.18),
                  size: 17)),
          Center(
              child: Icon(accent.icon,
                  color: AppPreferences.palette.value.primary, size: 38)),
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

class _ImageSolverButtonState extends State<_ImageSolverButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
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
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPreferences.palette.value.secondary,
                  AppPreferences.palette.value.primary
                ]),
          ),
          child: const Icon(Icons.document_scanner_rounded,
              color: Colors.white, size: 42),
        ),
      ),
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  final Animation<double> animation;
  final double intervalStart;
  final Widget child;

  const _AnimatedIn(
      {required this.animation,
      required this.intervalStart,
      required this.child});

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
            color: color.withOpacity(.20),
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
              (_) => Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle)),
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
      offset: Offset(math.cos(controller.value * math.pi * 2) * 12,
          math.sin(controller.value * math.pi * 2) * 12),
      child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color.withOpacity(.7), shape: BoxShape.circle)),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final AnimationController controller;

  const _Sparkle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scale = .75 + (math.sin(controller.value * math.pi * 2) + 1) * .18;
    return Transform.scale(
        scale: scale,
        child: Icon(Icons.auto_awesome_rounded,
            color: AppPreferences.palette.value.secondary, size: 22));
  }
}

class _SubjectAccent {
  final IconData icon;
  final Color primary;
  final Color soft;
  final String description;

  const _SubjectAccent(
      {required this.icon,
      required this.primary,
      required this.soft,
      required this.description});
}

final _subjectAccents = [
  _SubjectAccent(
      icon: Icons.functions_rounded,
      primary: AppPreferences.palette.value.primary,
      soft: AppPreferences.palette.value.background.last,
      description: 'Build strong foundations in everyday math.'),
  _SubjectAccent(
      icon: Icons.bar_chart_rounded,
      primary: AppPreferences.palette.value.primary,
      soft: AppPreferences.palette.value.background.last,
      description: 'Explore data, variability, and chance.'),
  _SubjectAccent(
      icon: Icons.show_chart_rounded,
      primary: AppPreferences.palette.value.primary,
      soft: AppPreferences.palette.value.background.last,
      description: 'Prepare for advanced math concepts.'),
  _SubjectAccent(
      icon: Icons.integration_instructions_rounded,
      primary: AppPreferences.palette.value.primary,
      soft: AppPreferences.palette.value.background.last,
      description: 'Differentiate, integrate, and understand change.'),
];
