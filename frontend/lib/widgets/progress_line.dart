import 'package:flutter/material.dart';

import '../services/app_preferences.dart';

class ProgressLine extends StatelessWidget {
  final int percent;
  final double height;

  const ProgressLine({super.key, required this.percent, this.height = 10});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: (percent.clamp(0, 100) as int) / 100,
        minHeight: height,
        backgroundColor: palette.primary.withOpacity(.12),
        valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
      ),
    );
  }
}
