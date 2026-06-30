import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';
import '../../theme/app_theme.dart';

/// A static, premium mesh background of soft color blobs over the page base.
/// (Previously animated — the motion was dropped on purpose; the blobs now
/// sit still.) Colors are always derived from the active [MathiviaPalette],
/// so it automatically follows the user's color preference.
///
/// The blobs adapt to brightness: in light mode the palette color is softened
/// toward white (a light, pastel tint) at low opacity; in dark mode it stays
/// very faint so the page reads as near-black with only a hint of color.
///
/// [vivid] swaps in a larger, more central set of blobs over a faint tinted
/// (not flat) base -- needed for screens that put a glass/frosted surface
/// (see GlassCard) on top, since a blur effect has nothing to refract over
/// the default subtle, corner-pinned blobs. Defaults to false so every
/// existing screen's look is unchanged.
class AnimatedBackground extends StatelessWidget {
  final Widget child;
  final bool vivid;
  const AnimatedBackground({super.key, required this.child, this.vivid = false});

  /// In light mode, blend the (often vivid) palette color toward white so the
  /// background tint is soft and pastel rather than a strong saturated wash.
  /// In dark mode, leave it as-is — opacity alone keeps it faint over black.
  Color _tint(Color c, bool isDark) =>
      isDark ? c : Color.lerp(c, Colors.white, 0.15)!;

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.colorsOf(context).pageBg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final primary = _tint(palette.primary, isDark);
        final secondary = _tint(palette.secondary, isDark);

        if (!vivid) {
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: base),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(-0.7, -0.9),
                  child: _Blob(
                    color: primary.withOpacity(isDark ? 0.06 : 0.09),
                    size: 280,
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0.8, 0.95),
                  child: _Blob(
                    color: secondary.withOpacity(isDark ? 0.07 : 0.10),
                    size: 240,
                  ),
                ),
              ),
              child,
            ],
          );
        }

        // Vivid mode: a faintly tinted base plus larger blobs near the
        // *center* of the screen (not just corners), so a frosted/glass
        // surface placed on top has something behind it to blur and refract.
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
                        primary.withOpacity(isDark ? 0.14 : 0.16), base),
                    Color.alphaBlend(
                        secondary.withOpacity(isDark ? 0.12 : 0.14), base),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(-0.3, -0.6),
                child: _Blob(
                  color: primary.withOpacity(isDark ? 0.28 : 0.42),
                  size: 460,
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0.4, 0.7),
                child: _Blob(
                  color: secondary.withOpacity(isDark ? 0.26 : 0.40),
                  size: 420,
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0.7, -0.5),
                child: _Blob(
                  color: primary.withOpacity(isDark ? 0.20 : 0.30),
                  size: 320,
                ),
              ),
            ),
            child,
          ],
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
