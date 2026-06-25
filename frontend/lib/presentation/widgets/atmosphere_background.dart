import 'dart:ui';
import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';

/// Rich atmospheric background for auth-flow screens (onboarding, login,
/// register). More expressive than AnimatedBackground — uses a
/// CustomPaint base gradient and blurred orb overlays drawn from the
/// active palette, adapted from mathiva(2)'s _PurpleAtmospherePainter.
///
/// Unlike AnimatedBackground this is static (no animation controller) to
/// keep auth screens feeling calm and grounded rather than restless.
///
/// Usage:
///   return Scaffold(
///     body: AtmosphereBackground(
///       child: SafeArea(...),
///     ),
///   );
class AtmosphereBackground extends StatelessWidget {
  final Widget child;
  const AtmosphereBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient + wash orbs via CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: _AtmospherePainter(palette),
              ),
            ),
            // Foreground content
            child,
          ],
        );
      },
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final MathiviaPalette palette;
  const _AtmospherePainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    // ── Base gradient ────────────────────────────────────────────────────────
    // Very faint tri-stop gradient from the palette's background stops so
    // the atmosphere shifts with the user's chosen palette color.
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.background[0],
          palette.background[1],
          palette.background[2],
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    // ── Top wash ─────────────────────────────────────────────────────────────
    // A broad elliptical wash at the top using the palette secondary —
    // gives the header area a subtle glow that frames the logo/branding.
    final topWash = Paint()
      ..color = palette.secondary.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawOval(
      Rect.fromLTWH(-60, 20, size.width * 1.2, 240),
      topWash,
    );

    // ── Right-center wash ────────────────────────────────────────────────────
    // Offset toward the right and middle so the composition has diagonal
    // tension rather than just top-to-bottom.
    final rightWash = Paint()
      ..color = palette.primary.withOpacity(0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 96);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.45, 100, size.width * 0.80, 280),
      rightWash,
    );

    // ── Lower wash ───────────────────────────────────────────────────────────
    // Anchors the bottom of the screen with a complementary tint,
    // keeping the CTA button area from feeling detached from the atmosphere.
    final lowerWash = Paint()
      ..color = palette.primary.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 88);
    canvas.drawOval(
      Rect.fromLTWH(-80, size.height * 0.64, size.width * 1.1, 240),
      lowerWash,
    );

    // ── Floating orbs ────────────────────────────────────────────────────────
    // Two small glassy spheres add depth without cluttering the screen.
    _drawOrb(
      canvas,
      center: Offset(size.width * 0.10, size.height * 0.28),
      radius: 30,
      primary: palette.primary,
      highlight: palette.secondary,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 0.88, size.height * 0.14),
      radius: 32,
      primary: palette.secondary,
      highlight: palette.primary,
    );
  }

  void _drawOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color primary,
    required Color highlight,
  }) {
    // Drop shadow beneath the orb
    final shadow = Paint()
      ..color = primary.withOpacity(0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center.translate(0, 8), radius * 0.9, shadow);

    // Orb body — radial gradient creates the glassy illusion
    final orb = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.55),
        radius: 0.95,
        colors: [
          Colors.white.withOpacity(0.92),
          highlight.withOpacity(0.45),
          primary.withOpacity(0.18),
        ],
        stops: const [0.02, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orb);
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.palette != palette;
}
