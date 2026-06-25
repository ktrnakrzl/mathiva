import 'package:flutter/material.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../utils/route_names.dart';
import '../presentation/widgets/atmosphere_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/primary_button.dart';

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
      title: 'Scan Any Problem',
      subtitle: 'AI-powered solving in seconds.',
      icon: Icons.document_scanner_rounded,
    ),
    _OnboardingSlide(
      title: 'Understand Every Step',
      subtitle: 'Clear explanations that make sense.',
      icon: Icons.lightbulb_outline_rounded,
    ),
    _OnboardingSlide(
      title: 'Track Your Progress',
      subtitle: 'Build confidence every day.',
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
    final _chip = Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AtmosphereBackground(
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
                PrimaryButton(
                  label: _index == _slides.length - 1 ? 'Get Started' : 'Next',
                  onPressed: _next,
                  height: 56,
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
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 35,
                height: 1.16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero section: the icon itself is the focal point — no card, no ring,
/// no drop shadow. Just a very soft, wide, low-opacity glow behind it so
/// the icon has air to breathe without competing visual weight.
class _Hero extends StatelessWidget {
  final _OnboardingSlide slide;
  final Color primary;

  const _Hero({
    required this.slide,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle wide glow — soft and translucent, never a hard-edged
            // shape competing with the icon.
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withOpacity(0.16),
                    primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            Icon(slide.icon, color: primary, size: 96),
          ],
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