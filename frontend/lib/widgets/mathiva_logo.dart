import 'package:flutter/material.dart';

import '../services/app_preferences.dart';

class MathivaLogo extends StatelessWidget {
  final double size;
  const MathivaLogo({super.key, this.size = 86});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(palette.primary, BlendMode.srcIn),
      child: Image.asset(
        'assets/mathiva_logo.png',
        height: size,
        width: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
