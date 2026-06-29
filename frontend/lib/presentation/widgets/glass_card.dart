import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'tap_scale.dart';

/// A genuinely translucent glass surface: blurs whatever is behind it (the
/// vivid blobs in [AnimatedBackground]'s vivid mode) through a real
/// [BackdropFilter], with a light, low-opacity tint over the top -- so the
/// colorful backdrop actually shows through the card instead of being
/// replaced by a solid fill. Content inside stays dark (_ink/_muted,
/// palette-primary outline buttons) since the visible surface reads as a
/// light frosted tint, not a vivid block.
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
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.onTap,
    this.blurSigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            // Low opacity on purpose -- this is what makes it "glass" rather
            // than a solid card. The vivid background blobs need to show
            // through visibly. Tokens come from SemanticColors so dark mode
            // gets a much lower-opacity tint instead of washing out.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.glassFillStart, colors.glassFillEnd],
            ),
            border: Border.all(color: colors.glassBorder, width: 1.2),
            // Neutral elevation shadow -- a brand-tinted (primary) shadow
            // here read as a visible purple glow/smudge under every card in
            // both themes since it ignored the actual theme; black at low
            // opacity reads as normal depth instead. Dark mode needs a much
            // higher opacity since the shadow has to read against an
            // already-dark page background, not white.
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.75 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return TapScale(onTap: onTap, child: card);
  }
}
