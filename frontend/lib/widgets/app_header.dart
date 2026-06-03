import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/app_preferences.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;

  const AppHeader({super.key, required this.title, this.subtitle, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBack)
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity( .86),
            ),
          ),
        if (showBack) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -.2)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity( .80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity( .9)),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: palette.primary, size: 22),
        ),
      ],
    );
  }
}
