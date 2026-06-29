import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';
import '../../theme/app_theme.dart';

/// FULL REDESIGN: premium animated mesh background with floating symbols.
/// Colors are always derived from the active [MathiviaPalette], so it
/// automatically follows the user's color preference.
///
/// [vivid] swaps in a much larger, more saturated, more central set of
/// blobs over a faint tinted (not flat white) base -- needed for screens
/// that put a glass/frosted surface (see GlassCard) on top, since a blur
/// effect has nothing to refract over the default subtle, corner-pinned
/// blobs. Defaults to false so every existing screen's look is unchanged.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool vivid;
  const AnimatedBackground({super.key, required this.child, this.vivid = false});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.colorsOf(context).pageBg;

    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final bg = palette.background;
        final colors = bg.length >= 2 ? bg : [bg.first, bg.first];

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;

            if (!widget.vivid) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: base),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(
                        -0.7 + 0.25 * math.sin(t),
                        -0.9 + 0.18 * math.cos(t * 0.8),
                      ),
                      child: _Blob(
                        color: palette.primary.withOpacity(0.12),
                        size: 280,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(
                        0.8 + 0.20 * math.cos(t * 0.7),
                        0.95 + 0.15 * math.sin(t * 0.9),
                      ),
                      child: _Blob(
                        color: palette.secondary.withOpacity(0.14),
                        size: 240,
                      ),
                    ),
                  ),
                  widget.child,
                ],
              );
            }

            // Vivid mode: a tinted base plus larger, more saturated blobs
            // that sweep across the *center* of the screen (not just
            // corners), so a frosted/glass surface placed on top actually
            // has something colorful behind it to blur and refract.
            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                            palette.primary.withOpacity(0.10), base),
                        Color.alphaBlend(
                            palette.secondary.withOpacity(0.08), base),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      -0.3 + 0.55 * math.sin(t),
                      -0.6 + 0.35 * math.cos(t * 0.8),
                    ),
                    child: _Blob(
                      color: palette.primary.withOpacity(0.40),
                      size: 460,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      0.4 + 0.50 * math.cos(t * 0.7),
                      0.7 + 0.30 * math.sin(t * 0.9),
                    ),
                    child: _Blob(
                      color: palette.secondary.withOpacity(0.42),
                      size: 420,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      0.7 + 0.25 * math.sin(t * 1.1),
                      -0.5 + 0.30 * math.cos(t * 0.6),
                    ),
                    child: _Blob(
                      color: palette.primary.withOpacity(0.30),
                      size: 320,
                    ),
                  ),
                ),
                widget.child,
              ],
            );
          },
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

// FULL REDESIGN PATCH APPLIED
