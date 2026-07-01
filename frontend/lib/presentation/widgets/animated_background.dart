import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A plain solid canvas ([SemanticColors.pageBg]).
///
/// In the shadcn/ui reskin the background is a flat near-white / near-black
/// surface — the previous soft color-blob "mesh" was removed. This is kept as
/// a thin wrapper (with the same `vivid` constructor param, now ignored) so the
/// many screens that wrap their body in an [AnimatedBackground] don't need to
/// change.
class AnimatedBackground extends StatelessWidget {
  final Widget child;
  final bool vivid; // retained for call-site compatibility; unused.
  const AnimatedBackground({super.key, required this.child, this.vivid = false});

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.colorsOf(context).pageBg;
    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: child,
    );
  }
}
