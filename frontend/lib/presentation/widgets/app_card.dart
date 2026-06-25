import 'package:flutter/material.dart';

/// Standardised white card used throughout the app.
///
/// Design spec (matches the migration plan target):
///   color:        Colors.white
///   borderRadius: 20
///   border:       1 px, Color(0xFFE5E7EB)
///   shadow:       blurRadius 16, offset (0, 4), color 0x0A000000
///
/// All inline BoxDecoration card patterns should be replaced with AppCard
/// during Milestones 3-4. Auth screens (onboarding, login, register) use
/// their own card variants — AppCard is for main-app content surfaces.
///
/// [padding] defaults to 20 on all sides. Override as needed.
/// [child] is required.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? shadow;

  static const _defaultBorder = Color(0xFFE5E7EB);
  static const _defaultShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.borderColor,
    this.shadow,
  });

  /// Convenience constructor for cards that need no padding — the child
  /// manages its own internal spacing (e.g. ListTile rows, divided lists).
  const AppCard.flat({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderColor,
    this.shadow,
  }) : padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? _defaultBorder, width: 1),
        boxShadow: shadow ?? _defaultShadow,
      ),
      child: child,
    );
  }
}
