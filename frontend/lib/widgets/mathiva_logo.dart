import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../theme/app_theme.dart';

class MathivaLogo extends StatelessWidget {
  final double size;
  const MathivaLogo({super.key, this.size = 86});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [palette.secondary, palette.primary]),
          ),
          child: const Center(
            child: Text('M', style: TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Mathivia', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.1)),
        const Text('Learn Math Smarter', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}
