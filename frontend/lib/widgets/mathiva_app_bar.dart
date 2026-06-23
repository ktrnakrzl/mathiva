import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

/// SHARED APP BAR
/// Mirrors the HomeScreen header exactly: the same lavender chrome surface
/// and hairline border, the same indigo title treatment used for page
/// titles ("Mathivia", "Progress"), and the same muted supporting-text
/// style used for subtitles. This keeps every screen that uses
/// MathivaAppBar feeling like part of the same header component family
/// as HomeScreen, rather than a visually distinct app bar.
class MathivaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBack;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  // Shared chrome tokens — identical to the lavender surface/border used by
  // HomeScreen's AppBar and MathivaBottomNav, so all app chrome reads as
  // one consistent surface.
  static const _chromeSurface = Color(0xFFF6F5FB);
  static const _chromeBorder = Color(0xFFEAE8F5);

  // Shared text tokens — identical to HomeScreen's title color and the
  // muted supporting-text color used across the app.
  static const _titleColor = Color(0xFF312E81);
  static const _muted = Color(0xFF6B7280);

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

    return AppBar(
      backgroundColor: _chromeSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // Matches HomeScreen's AppBar exactly: a barely-there shadow that
      // only appears once content scrolls beneath the header, giving
      // subtle separation from page content without a visible resting
      // shadow or heavy border.
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
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
      titleSpacing: showBack ? 0 : 20,
      title: Row(
        children: [
          // Icon badge — same soft primary-tinted chip used throughout the
          // app (HomeScreen action tiles, recent scans, stat cards) rather
          // than a standalone gradient treatment.
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _titleColor,
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
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: _chromeBorder,
        ),
      ),
    );
  }
}
