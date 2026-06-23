import 'package:flutter/material.dart';

import '../services/app_preferences.dart';

class AppColors {
  static const purple = Color(0xFF7A3CFF);
  static const violet = Color(0xFF7A3CFF);
  static const pink = Color(0xFFFF63C3);
  static const orange = Color(0xFFFF922B);
  static const sky = Color(0xFFEFFFF6);
  static const blush = Color(0xFFF0FFF4);
  static const ink = Color(0xFF252238);
  static const muted = Color(0xFF7C7890);
}

class AppTheme {
  static MathiviaPalette paletteOf(BuildContext context) =>
      AppPreferences.palette.value;
  static Color primaryOf(BuildContext context) => paletteOf(context).primary;
  static Color secondaryOf(BuildContext context) =>
      paletteOf(context).secondary;
  static List<Color> backgroundOf(BuildContext context) =>
      paletteOf(context).background;

  static ThemeData light([MathiviaPalette? palette]) {
    final active = palette ?? AppPreferences.palette.value;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: active.primary,
        primary: active.primary,
        secondary: active.secondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? active.primary : null),
        trackColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? active.primary.withOpacity(.35)
                : null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? active.primary : null),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFF7F9FC),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F9FC).withOpacity(.84),
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: active.primary, width: 1.8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: active.primary,
        contentTextStyle: const TextStyle(
            color: const Color(0xFFF7F9FC), fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      timePickerTheme: TimePickerThemeData(
        dialHandColor: active.primary,
        hourMinuteTextColor: AppColors.ink,
        dayPeriodTextColor: AppColors.ink,
      ),
    );
  }
}
