import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';

/// Outlined secondary action button — used alongside PrimaryButton when
/// the screen has two CTAs of different importance (e.g. "Try Again" vs
/// "Next Concept", or "Continue with Google" vs "Log In").
///
/// Design spec:
///   border:       palette.primary @ 30 % opacity, 1.2 px
///   foreground:   palette.primary
///   fill:         transparent
///   borderRadius: 16
///   height:       54
///   textStyle:    Poppins w600, 15.5 sp
///
/// [label] is required. [onPressed] null disables automatically.
/// [icon] is optional and placed before the label if supplied.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;
  final Widget? icon;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
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
        final enabled = onPressed != null;

        final content = icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 10),
                  Text(label),
                ],
              )
            : Text(label);

        return SizedBox(
          width: double.infinity,
          height: height,
          child: OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: enabled ? primary : primary.withOpacity(0.45),
              side: BorderSide(
                color: enabled
                    ? primary.withOpacity(0.30)
                    : primary.withOpacity(0.15),
                width: 1.2,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            child: content,
          ),
        );
      },
    );
  }
}
