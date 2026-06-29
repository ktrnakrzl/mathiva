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

const _navSurface = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFEFEDF7);
const _navInactive = Color(0xFF9CA3AF);

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
        final activeColor = palette.primary;

        return Container(
          decoration: BoxDecoration(
            color: _navSurface,
            border: Border(
              top: BorderSide(color: _navBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // ── Four flat items ──────────────────────────────────
                  Row(
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        selected: selected == MathivaTab.home,
                        activeColor: activeColor,
                        onTap: () => _go(context, MathivaTab.home),
                      ),
                      _NavItem(
                        icon: Icons.menu_book_rounded,
                        label: 'Lessons',
                        selected: selected == MathivaTab.lessons,
                        activeColor: activeColor,
                        onTap: () => _go(context, MathivaTab.lessons),
                      ),
                      // Center gap for FAB
                      const Expanded(child: SizedBox()),
                      _NavItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Progress',
                        selected: selected == MathivaTab.progress,
                        activeColor: activeColor,
                        onTap: () => _go(context, MathivaTab.progress),
                      ),
                      _NavItem(
                        icon: Icons.more_horiz_rounded,
                        label: 'More',
                        selected: selected == MathivaTab.settings,
                        activeColor: activeColor,
                        onTap: () => _go(context, MathivaTab.settings),
                      ),
                    ],
                  ),

                  // ── Center FAB ───────────────────────────────────────
                  Positioned(
                    top: -20,
                    child: GestureDetector(
                      onTap: () => _go(context, MathivaTab.scan),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withOpacity(0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Nav Item ──────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : _navInactive;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
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