import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../utils/route_names.dart';

enum MathivaTab {
  home,
  chat,
  scan,
  progress,
  profile,
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
      MathivaTab.chat => RouteNames.chat,
      MathivaTab.scan => RouteNames.imageSolver,
      MathivaTab.progress => RouteNames.progress,
      MathivaTab.profile => RouteNames.profile,
    };

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(.95),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
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
              onTap: () => _go(context, MathivaTab.home),
            ),

            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              selected: selected == MathivaTab.chat,
              onTap: () => _go(context, MathivaTab.chat),
            ),

            _ScanButton(
              selected: selected == MathivaTab.scan,
              onTap: () => _go(context, MathivaTab.scan),
            ),

            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Progress',
              selected: selected == MathivaTab.progress,
              onTap: () => _go(context, MathivaTab.progress),
            ),

            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: selected == MathivaTab.profile,
              onTap: () => _go(context, MathivaTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _ScanButton({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? const [
                      Color(0xFF6D3DFF),
                      Color(0xFF8A5EFF),
                    ]
                  : const [
                      Color(0xFF7C4DFF),
                      Color(0xFF9B6DFF),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withOpacity(
                  selected ? .50 : .35,
                ),
                blurRadius: selected ? 40 : 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 30,
          ),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;

    final color = selected
        ? palette.primary
        : const Color(0xFF9CA3AF);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              scale: selected ? 1.08 : 1,
              child: Icon(
                icon,
                size: 27,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}