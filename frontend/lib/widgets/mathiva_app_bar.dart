import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// SHARED APP BAR (detail screens)
/// A flat shadcn/ui header: a solid canvas background with a single hairline
/// bottom border — no glass/blur. A small accent-tinted icon chip sits beside
/// the title; the optional back button uses the muted text color. Used by
/// non-tab screens (lesson detail, concept, practice, result, etc.); the main
/// tabs use [MathivaTopBar] instead.
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
    final colors = AppTheme.colorsOf(context);

    return AppBar(
      backgroundColor: colors.pageBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: subtitle != null ? 74 : 58,
      leadingWidth: showBack ? 52 : 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: colors.muted,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      titleSpacing: showBack ? 0 : 18,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.ring,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.serif(
                  color: colors.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
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
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: colors.border),
      ),
    );
  }
}
