import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../theme/app_theme.dart';

/// The shadcn/ui app-shell top bar, shared by every main tab (Home, Lessons,
/// Chat, Scan, Progress, Settings). Flat — a solid canvas background with a
/// single hairline bottom border (no glass/blur).
///
/// Left: the Mathiva "M" logo mark (assets/mathiva_logo.png) + the "Mathiva"
/// wordmark. Right: a single ghost icon button that toggles light/dark mode
/// (the theme toggle now lives here instead of in Settings).
///
/// Per-screen titles ("Lessons", "Progress", …) live in the scroll body as a
/// 26px heading, not here — the top bar stays constant across tabs.
class MathivaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MathivaTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(59);

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.pageBg,
        border: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          child: Row(
            children: [
              // Logo mark — the Mathiva "M" brand image.
              Image.asset(
                'assets/mathiva_logo.png',
                height: 30,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 9),
              Text(
                'Mathiva',
                style: AppTheme.serif(
                  color: colors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Light/dark mode toggle (replaces the old avatar/chat controls).
              const _ThemeToggleButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ghost icon button that flips [AppPreferences.darkMode]. Shows a moon while
/// in light mode (tap → go dark) and a sun while in dark mode (tap → go light).
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return ValueListenableBuilder<bool>(
      valueListenable: AppPreferences.darkMode,
      builder: (context, isDark, _) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => AppPreferences.darkMode.value = !isDark,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 20,
                color: colors.muted,
              ),
            ),
          ),
        );
      },
    );
  }
}
