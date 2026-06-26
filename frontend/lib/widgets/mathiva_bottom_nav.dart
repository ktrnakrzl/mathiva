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

// The bar's surface — flat and opaque, no glassmorphism, no blur. A
// near-white surface with a hairline border, matching the calm, minimal
// chrome language used by the header and onboarding/login screens.
const _navSurface = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFEFEDF7);

// Inactive icons/labels stay a neutral gray rather than a tinted purple, so
// the single active item is the only thing carrying color.
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
        // Softer purple for the active state — the brand primary blended
        // toward white, so it reads as gentle rather than the saturated
        // brand color used for primary CTAs elsewhere.
        final activeColor = Color.lerp(palette.primary, Colors.white, 0.30)!;

        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: _navSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _navBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                _NavItem(
                  icon: Icons.document_scanner_rounded,
                  label: 'Scan',
                  selected: selected == MathivaTab.scan,
                  activeColor: activeColor,
                  onTap: () => _go(context, MathivaTab.scan),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Progress',
                  selected: selected == MathivaTab.progress,
                  activeColor: activeColor,
                  onTap: () => _go(context, MathivaTab.progress),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: selected == MathivaTab.settings,
                  activeColor: activeColor,
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
// The previous version overflowed because the outer bar had a hard 72 px
// height while each item's content (padding + icon + gap + label +
// padding) added up to more than the space that left after the bar's own
// padding — increasing icon/label size without rebalancing the padding
// pushed it over. Padding and gap are now trimmed so everything fits
// comfortably inside the same 72 px ceiling, with a bit more width per
// item (wider margin) for breathing room between tabs.

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
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? activeColor.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22.5),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}