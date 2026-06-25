import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';

/// Filled primary action button — the single most important CTA on any screen.
///
/// Design spec:
///   background:   palette.primary
///   foreground:   Colors.white
///   borderRadius: 16
///   height:       54
///   shadow:       blurRadius 18, offset (0, 8), palette.primary @ 22 %
///   textStyle:    Poppins w600, 15.5 sp
///
/// Replaces all OutlinedButton-as-primary and inline ElevatedButton usages
/// throughout the app during Milestones 2-4.
///
/// [label] is required. [onPressed] null disables the button automatically.
/// [loading] shows a spinner in place of the label text.
/// [height] and [borderRadius] can be overridden for edge cases (e.g. compact
/// screens in the auth flow adjust height slightly).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final double borderRadius;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.height = 54,
    this.borderRadius = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final primary = palette.primary;
        final enabled = onPressed != null && !loading;

        return SizedBox(
          width: double.infinity,
          height: height,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Ink(
              decoration: BoxDecoration(
                color: enabled ? primary : primary.withOpacity(0.48),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: primary.withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: enabled ? onPressed : null,
                splashColor: Colors.white.withOpacity(0.12),
                highlightColor: Colors.white.withOpacity(0.06),
                child: Center(
                  child: loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        )
                      : icon != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                icon!,
                                const SizedBox(width: 10),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
