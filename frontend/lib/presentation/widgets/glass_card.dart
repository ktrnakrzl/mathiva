import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'tap_scale.dart';

/// A flat shadcn/ui-style card: a solid [SemanticColors.surface] fill with a
/// 1px hairline border and a soft, subtle drop shadow. (Previously a "liquid
/// glass" surface with backdrop blur + specular sheen — that treatment was
/// dropped in the shadcn reskin in favour of clean, bordered, lightly-shadowed
/// panels.) The `blurSigma` parameter is retained but ignored so existing call
/// sites don't need to change.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double blurSigma; // retained for call-site compatibility; unused.

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.onTap,
    this.blurSigma = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: borderRadius,
        border: Border.all(color: colors.border, width: 1),
        // Exact shadcn card shadow tokens (light vs dark).
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF09090B).withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: const Color(0xFF09090B).withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return TapScale(onTap: onTap, child: card);
  }
}
