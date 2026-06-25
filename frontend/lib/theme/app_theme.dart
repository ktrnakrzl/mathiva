import 'package:flutter/material.dart';

import '../services/app_preferences.dart';

// Legacy color constants — kept for backward compatibility with any widget
// that still imports AppColors from this file directly. New code should use
// the file-local token constants (_ink, _muted, etc.) in each screen instead.
class AppColors {
  static const purple = Color(0xFF7A3CFF);
  static const violet = Color(0xFF7A3CFF);
  static const pink = Color(0xFFFF63C3);
  static const orange = Color(0xFFFF922B);
  static const sky = Color(0xFFEFFFF6);
  static const blush = Color(0xFFF0FFF4);
  static const ink = Color(0xFF111827);   // updated to match screen-level _ink
  static const muted = Color(0xFF6B7280); // updated to match screen-level _muted
}

class AppTheme {
  static MathiviaPalette paletteOf(BuildContext context) => AppPreferences.palette.value;
  static Color primaryOf(BuildContext context) => paletteOf(context).primary;
  static Color secondaryOf(BuildContext context) => paletteOf(context).secondary;
  static List<Color> backgroundOf(BuildContext context) => paletteOf(context).background;

  static ThemeData light([MathiviaPalette? palette]) {
    final active = palette ?? AppPreferences.palette.value;

    // The scaffold background is the last stop of the palette's background
    // gradient — a very faint tint that gives every screen a soft atmospheric
    // quality without competing with the white card surfaces above it.
    final scaffoldBg = active.background.last;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: active.primary,
        primary: active.primary,
        secondary: active.secondary,
        surface: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? active.primary : null,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? active.primary.withOpacity(.35)
              : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? active.primary : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: AppColors.muted.withOpacity(0.45), width: 1.5),
      ),
      appBarTheme: AppBarTheme(
        // Default AppBar is the chrome-surface tint; screens that need a
        // transparent or custom AppBar override this individually.
        backgroundColor: const Color(0xFFF6F5FB),
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.04),
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF312E81),
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(
          color: AppColors.muted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: active.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: active.primary.withOpacity(0.12), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: active.primary.withOpacity(0.12), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: active.primary.withOpacity(0.45), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: active.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: active.primary,
          side: BorderSide(color: active.primary.withOpacity(0.35), width: 1.2),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: active.primary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      timePickerTheme: TimePickerThemeData(
        dialHandColor: active.primary,
        hourMinuteTextColor: AppColors.ink,
        dayPeriodTextColor: AppColors.ink,
      ),
    );
  }
}