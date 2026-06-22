import 'package:flutter/material.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../utils/route_names.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';

final _primary = Color(0xFF2563EB);
final _secondary = Color(0xFF14B8A6);
final _chip = Color(0xFFEFF6FF);

final _ink = Color(0xFF242033);
final _muted = Color(0xFF8C879A);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _slides = [
    _OnboardingSlide(
      title: 'Scan Any Math Problem',
      subtitle:
          'Snap a photo of equations, word problems, or handwritten work and let Mathiva detect what you need.',
      icon: Icons.document_scanner_rounded,
    ),
    _OnboardingSlide(
      title: 'Step-by-Step Solutions',
      subtitle:
          'Understand every move with clean explanations, visual cards, and final answers you can trust.',
      icon: Icons.lightbulb_outline_rounded,
    ),
    _OnboardingSlide(
      title: 'Track Your Growth',
      subtitle:
          'Build streaks, monitor topic mastery, and keep practicing exactly where you need support.',
      icon: Icons.trending_up_rounded,
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
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;
    final _secondary = _palette.secondary;
    final _gBackgroundStart = _palette.background.first;
    final _chip = Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.login),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: _chip,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: _ink.withOpacity(0.55),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (value) => setState(() => _index = value),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) => _SlidePage(
                      slide: _slides[index],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: _index == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _index == index ? _primary : _chip,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _next,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _primary,
                      side: BorderSide(color: _primary, width: 1),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _index == _slides.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;

    return FadeSlideIn(
      key: ValueKey(slide.title),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Hero(slide: slide, primary: _primary),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 26,
                height: 1.22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 14.5,
                height: 1.65,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero section: one calm focal plate behind the icon, framed by a thin
/// outer ring for quiet depth. No competing shapes, no extra ornament —
/// just enough structure that the circle reads as designed, not dropped in.
class _Hero extends StatelessWidget {
  final _OnboardingSlide slide;
  final Color primary;

  const _Hero({
    required this.slide,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      alignment: Alignment.center,
      child: Container(
        width: 152,
        height: 152,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primary.withOpacity(0.14),
            width: 1.2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.alphaBlend(primary.withOpacity(0.10), Colors.white),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(slide.icon, color: primary, size: 52),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}