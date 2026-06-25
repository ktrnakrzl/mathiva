import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';

/// Ambient animated background used by all main-app screens.
///
/// Two radial blobs drift slowly using palette.primary and palette.secondary
/// at low opacity, over the scaffold background (which is now the palette's
/// faint background tint from AppTheme). The base layer is transparent so
/// the scaffold's own background color shows through cleanly.
///
/// With the palette background tints restored in AppPreferences, the blobs
/// are now subtly visible — a soft colored atmosphere rather than invisible
/// motion on a white canvas.
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
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Primary blob — upper-left, drifts gently
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      -0.7 + 0.22 * math.sin(t),
                      -0.9 + 0.16 * math.cos(t * 0.8),
                    ),
                    child: _Blob(
                      color: palette.primary.withOpacity(0.10),
                      size: 300,
                    ),
                  ),
                ),
                // Secondary blob — lower-right, counter-drifts
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      0.85 + 0.18 * math.cos(t * 0.7),
                      0.90 + 0.14 * math.sin(t * 0.9),
                    ),
                    child: _Blob(
                      color: palette.secondary.withOpacity(0.08),
                      size: 260,
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