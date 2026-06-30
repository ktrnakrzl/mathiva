import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/app_preferences.dart';
import '../theme/app_theme.dart';

/// SHARED APP BAR
/// A frosted-glass header: real backdrop blur (via [BackdropFilter]) over a
/// translucent white tint, so the animated background blobs behind it stay
/// visible through the bar instead of being hidden by a flat surface. This
/// matches the glass treatment used by GlassCard, so app chrome and content
/// surfaces read as one consistent visual language. Title/subtitle text
/// stays on the same indigo/muted tokens used everywhere else.
class MathivaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBack;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const MathivaAppBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.showBack = true,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.onBack,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 74 : 58);

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    final primary = palette.primary;
    final colors = AppTheme.colorsOf(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          backgroundColor: colors.glassFillStart,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          // Soft neutral shadow on scroll — matches GlassCard's liquid-glass
          // treatment (a colored glow would read as a tint, not glass).
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withOpacity(0.08),
          automaticallyImplyLeading: automaticallyImplyLeading,
          toolbarHeight: subtitle != null ? 74 : 58,
          leadingWidth: showBack ? 52 : 0,
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: primary,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                )
              : null,
          titleSpacing: 0,
          centerTitle: true,
          title: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon badge — same soft primary-tinted chip used throughout
                // the app (HomeScreen action tiles, recent scans, stat cards)
                // rather than a standalone gradient treatment.
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primary, size: 17),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.titleColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.muted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: colors.glassBorder,
            ),
          ),
        ),
      ),
    );
  }
}
