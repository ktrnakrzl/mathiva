import 'package:flutter/material.dart';

import '../services/app_preferences.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const GradientBackground(
      {super.key, required this.child, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(child: child);

    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: scrollable
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 48),
                        child: content,
                      ),
                    );
                  },
                )
              : content,
        );
      },
    );
  }
}
