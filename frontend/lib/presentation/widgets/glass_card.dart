import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'tap_scale.dart';

/// A "liquid glass" surface in the spirit of iOS 26: mostly *clear* (only a
/// light backdrop blur, so the content/background behind shows through), with
/// the effect carried by a crisp white specular rim and a faint top-lit tint
/// rather than a heavy frost. A soft *neutral* drop shadow (no colored glow)
/// gives it a gentle lift. Content inside stays dark since the surface is only
/// a light tint, not a solid block.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.onTap,
    this.blurSigma = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = DecoratedBox(
      // Soft, neutral, diffuse shadow -- two layers: a wide ambient one for
      // depth and a tight contact one just under the card. Neutral (not
      // brand-tinted) so it reads as glass, not a glow. Lives on an OUTER box
      // so it sits behind the clipped glass instead of being clipped away.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  // Base fill: a faint top-lit tint that lets the colored
                  // background show through. Tokens come from SemanticColors
                  // so dark mode uses a lower-opacity frost.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.glassFillStart, colors.glassFillEnd],
                  ),
                  // Crisp white specular rim.
                  border: Border.all(color: colors.glassBorder, width: 1),
                ),
                child: child,
              ),
              // Glossy specular sheen: a bright diagonal highlight pooled in
              // the top-left and fading out by the middle. THIS is what makes
              // the surface read as glossy "liquid glass" (light reflecting
              // off the surface) rather than a flat translucent panel.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.16 : 0.40),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return TapScale(onTap: onTap, child: card);
  }
}
