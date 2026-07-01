import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../utils/route_names.dart';

enum MathivaTab {
  home,
  tutor,
  scan,
  learn,
  settings,
}

/// The shadcn/ui bottom navigation: a flat full-width bar with a single
/// hairline top border. Five destinations — four standard tabs (icon + 11px
/// label, accent when active, faint at rest) evenly flanking the emphasised
/// center "Scan" action, a raised 46×46 accent-filled rounded-square with a
/// soft accent-tinted shadow. Lessons + Progress are merged into one "Learn"
/// tab so Scan stays perfectly centered.
class MathivaBottomNav extends StatelessWidget {
  final MathivaTab selected;

  const MathivaBottomNav({
    super.key,
    required this.selected,
  });

  void _go(BuildContext context, MathivaTab tab) {
    if (selected == tab) return;
    final route = switch (tab) {
      MathivaTab.home => RouteNames.home,
      MathivaTab.tutor => RouteNames.chat,
      MathivaTab.scan => RouteNames.imageSolver,
      MathivaTab.learn => RouteNames.learn,
      MathivaTab.settings => RouteNames.profile,
    };
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.pageBg,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: selected == MathivaTab.home,
                onTap: () => _go(context, MathivaTab.home),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Tutor',
                selected: selected == MathivaTab.tutor,
                onTap: () => _go(context, MathivaTab.tutor),
              ),
              _ScanItem(
                selected: selected == MathivaTab.scan,
                onTap: () => _go(context, MathivaTab.scan),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: 'Learn',
                selected: selected == MathivaTab.learn,
                onTap: () => _go(context, MathivaTab.learn),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                selected: selected == MathivaTab.settings,
                onTap: () => _go(context, MathivaTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Standard Nav Item ──────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final color = selected ? colors.accent : colors.subtleMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Raised "Scan" primary-action item ──────────────────────────────────────
class _ScanItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _ScanItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Transform.translate(
          offset: const Offset(0, -8),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withOpacity(selected ? 0.55 : 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.center_focus_strong_rounded,
              color: colors.onAccent,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
