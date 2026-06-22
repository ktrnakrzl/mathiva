import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../utils/route_names.dart';

enum MathivaTab {
  home,
  lessons,
  scan,
  progress,
  settings,
}

// Shared tokens — mirrors the palette established on HomeScreen so the nav
// reads as part of the same surface system rather than a separate component.
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);

// Shared app-chrome surface — same very light lavender tint used by the
// HomeScreen header, so header and bottom nav read as one "chrome" layer
// distinct from the white content surfaces between them.
const _chromeSurface = Color(0xFFF6F5FB);
const _chromeBorder = Color(0xFFEAE8F5);

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
      MathivaTab.lessons => RouteNames.subjects,
      MathivaTab.scan => RouteNames.imageSolver,
      MathivaTab.progress => RouteNames.progress,
      MathivaTab.settings => RouteNames.profile,
    };
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final primary = palette.primary;

        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _chromeSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _chromeBorder, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: selected == MathivaTab.home,
                  primary: primary,
                  onTap: () => _go(context, MathivaTab.home),
                ),
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Lessons',
                  selected: selected == MathivaTab.lessons,
                  primary: primary,
                  onTap: () => _go(context, MathivaTab.lessons),
                ),
                _NavItem(
                  icon: Icons.document_scanner_rounded,
                  label: 'Scan',
                  selected: selected == MathivaTab.scan,
                  primary: primary,
                  onTap: () => _go(context, MathivaTab.scan),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Progress',
                  selected: selected == MathivaTab.progress,
                  primary: primary,
                  onTap: () => _go(context, MathivaTab.progress),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: selected == MathivaTab.settings,
                  primary: primary,
                  onTap: () => _go(context, MathivaTab.settings),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────
// Every tab — including Scan — shares this exact treatment: an icon inside
// a soft primary-tinted chip when active, muted and unadorned at rest. This
// is the same icon-container motif HomeScreen uses everywhere (action
// tiles, recent scan rows, the focus card), so the bar reads as one surface
// in the same system rather than a generic Material nav with a CTA bolted
// onto it.

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? primary : _muted;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 38,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? primary.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: selected ? 22 : 21),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}