import 'package:flutter/material.dart';

/// Previously wrapped [child] with a fade + upward slide entrance animation.
/// The entrance animation was removed on request — content now appears
/// immediately with no fade-in. Kept as a pass-through (same constructor) so
/// the many call sites don't need to change.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offsetY = 24,
  });

  @override
  Widget build(BuildContext context) => child;
}
