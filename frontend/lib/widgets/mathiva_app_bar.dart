import 'package:flutter/material.dart';

class MathivaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final String? subtitle;
  final IconData? icon;

  const MathivaAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.actions,
    this.subtitle,
    this.icon,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF6F2FF),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.08),
      centerTitle: true,
      toolbarHeight: 52,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: showBack
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF312E81),
              ),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              splashRadius: 20,
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF312E81),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1,
        ),
      ),
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: 4),
            ]
          : null,
    );
  }
}

/// A plain icon button for use in [MathivaAppBar] actions.
class AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const AppBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF312E81), size: 21),
        tooltip: tooltip,
        splashRadius: 20,
        onPressed: onTap,
      ),
    );
  }
}