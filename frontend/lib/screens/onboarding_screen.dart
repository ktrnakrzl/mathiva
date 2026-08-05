import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/route_names.dart';
import '../presentation/widgets/auth_art.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../theme/app_theme.dart';

/// Onboarding — three slides in the "mathematical notebook / blueprint" art
/// direction: a graph-paper illustration panel with a hand-drawn vector math
/// diagram per slide, an accent eyebrow, a serif display headline, and a muted
/// description. (Distinct from the rest of the app's shadcn look, per the
/// auth-flow design handoff.)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      fig: 'fig. 1',
      eyebrow: 'SCAN',
      title: 'Snap any\nmath problem',
      subtitle: 'Point your camera and Mathiva reads it.',
      diagram: ParabolaDiagram(),
    ),
    _OnboardingSlide(
      fig: 'fig. 2',
      eyebrow: 'UNDERSTAND',
      title: 'Follow every\nstep clearly',
      subtitle: 'Every step explained, not just the answer.',
      diagram: TriangleDiagram(),
    ),
    _OnboardingSlide(
      fig: 'fig. 3',
      eyebrow: 'PROGRESS',
      title: 'Track your\ngrowth over time',
      subtitle: 'Build streaks and watch mastery climb.',
      diagram: GrowthDiagram(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      context.go(RouteNames.login);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
          child: Column(
            children: [
              // ── Top bar: brand lockup + Skip ──
              Row(
                children: [
                  const _LogoMark(),
                  const SizedBox(width: 10),
                  Text(
                    'Mathiva',
                    style: AppTheme.serif(
                      color: colors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(RouteNames.login),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: colors.muted,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (v) => setState(() => _index = v),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
                ),
              ),

              const SizedBox(height: 22),
              // ── Expanding pill-dot indicator ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = _index == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    width: active ? 26 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active ? colors.accent : colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),

              // ── Continue / Get Started ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withOpacity(0.32),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slide ───────────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return FadeSlideIn(
      key: ValueKey(slide.title),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration panel: graph paper + fig caption + diagram. Given a
          // fixed aspect (not Expanded) so the panel + title read as one block
          // centred vertically in the page.
          AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter:
                            GraphPaperPainter(line: graphPaperColor(context)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: FigCaption(slide.fig),
                    ),
                    // Symmetric vertical padding so the diagram sits dead-centre
                    // in the panel (the fig caption is a top-left overlay and
                    // doesn't shift it); Positioned.fill guarantees the Center
                    // measures against the whole panel, not a loose box.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 44),
                        child: Center(child: slide.diagram),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Accent eyebrow (colored text, no pill).
          Text(
            slide.eyebrow,
            style: TextStyle(
              color: colors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12 * 12,
            ),
          ),
          const SizedBox(height: 10),

          // Serif display headline.
          Text(
            slide.title,
            style: AppTheme.serif(
              color: colors.ink,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Short one-line description.
          Text(
            slide.subtitle,
            style: TextStyle(
              color: colors.muted,
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Brand logo mark ("M") ────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/mathiva_logo.png',
      height: 28,
      fit: BoxFit.contain,
    );
  }
}

class _OnboardingSlide {
  final String fig;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget diagram;

  const _OnboardingSlide({
    required this.fig,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.diagram,
  });
}
