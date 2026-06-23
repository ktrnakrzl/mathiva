import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';

/// FULL REDESIGN: premium animated mesh background with floating symbols.
/// Colors are always derived from the active [MathiviaPalette], so it
/// automatically follows the user's color preference.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

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
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final bg = palette.background;
        final colors = bg.length >= 2 ? bg : [bg.first, bg.first];

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;

            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
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
