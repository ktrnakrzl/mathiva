import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';

enum MathivaTab {
  home,
  lessons,
  scan,
  progress,
  settings,
}

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
        final colors = AppTheme.colorsOf(context);

        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              // Soft "liquid glass" — same BackdropFilter + frosted gradient
              // as GlassCard, so the nav reads as part of the same surface
              // system as the app bar and content cards rather than a
              // separate opaque bar.
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 68,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.glassFillStart, colors.glassFillEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.glassBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
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
    final color = selected ? primary : AppTheme.colorsOf(context).muted;

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
                color:
                    selected ? primary.withOpacity(0.08) : Colors.transparent,
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
