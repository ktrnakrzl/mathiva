import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../utils/route_names.dart';

// Kept class/file names for compatibility, but the user-facing name is Mathivia.
enum MathivaTab { home, progress, profile }

class MathivaBottomNav extends StatelessWidget {
  final MathivaTab selected;

  const MathivaBottomNav({super.key, required this.selected});

  void _go(BuildContext context, MathivaTab tab) {
    if (selected == tab) return;

    final route = switch (tab) {
      MathivaTab.home => RouteNames.home,
      MathivaTab.progress => RouteNames.progress,
      MathivaTab.profile => RouteNames.profile,
    };

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.94),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withOpacity(.95)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: selected == MathivaTab.home,
              onTap: () => _go(context, MathivaTab.home),
            ),
            _NavItem(
              icon: Icons.insert_chart_outlined_rounded,
              label: 'Progress',
              selected: selected == MathivaTab.progress,
              onTap: () => _go(context, MathivaTab.progress),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              selected: selected == MathivaTab.profile,
              onTap: () => _go(context, MathivaTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    final color = selected ? palette.primary : const Color(0xFF6D6978);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: selected ? 56 : 0,
              height: 4,
              margin: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: selected ? 1.07 : 1,
              child: Icon(icon, size: 31, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 13, fontWeight: selected ? FontWeight.w900 : FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
