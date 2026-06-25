import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

/// Shared AppBar used by secondary screens (solution, search, register,
/// practice, result, quiz, review, mastery, rewards, tutor).
///
/// Design system:
///  - Chrome surface: 0xFFF6F5FB (same lavender tint as HomeScreen AppBar
///    and MathivaBottomNav — all three pieces of app chrome read as one layer)
///  - Chrome border: 0xFFEAE8F5 (1 px hairline)
///  - Title color: 0xFF312E81 (indigo — consistent with every screen title)
///  - Icon badge: palette.primary at 10 % opacity
///  - Back arrow: palette.primary
///
/// No gradient. No diagnostic colors. Clean chrome surface only.
class MathivaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBack;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  static const _chromeSurface = Color(0xFFF6F5FB);
  static const _chromeBorder = Color(0xFFEAE8F5);
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
    final primary = AppPreferences.palette.value.primary;

    return AppBar(
      backgroundColor: _chromeSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: subtitle != null ? 74 : 58,
      leadingWidth: showBack ? 52 : 0,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: primary),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      titleSpacing: showBack ? 0 : 20,
      title: Row(
        children: [
          // Icon badge — soft primary-tinted chip matching the icon
          // treatment used in HomeScreen action tiles and stat cards.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.09),
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
        child: Container(height: 1, color: _chromeBorder),
      ),
    );
  }
}