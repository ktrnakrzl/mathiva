import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import 'semantic_colors.dart';

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

  /// The reactive light/dark neutral palette — read this instead of
  /// declaring local `_ink`/`_muted`/`_pageBg` consts in a screen.
  static SemanticColors colorsOf(BuildContext context) =>
      Theme.of(context).extension<SemanticColors>()!;

  static ThemeData light([MathiviaPalette? palette]) =>
      _build(palette, Brightness.light, SemanticColors.light);

  static ThemeData dark([MathiviaPalette? palette]) =>
      _build(palette, Brightness.dark, SemanticColors.dark);

  static ThemeData _build(
    MathiviaPalette? palette,
    Brightness brightness,
    SemanticColors colors,
  ) {
    final active = palette ?? AppPreferences.palette.value;
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: colors.pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: active.primary,
        primary: active.primary,
        secondary: active.secondary,
        brightness: brightness,
      ),
      extensions: [colors],
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
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: colors.ink,
      ),
      cardTheme: CardThemeData(
        color: isDark ? colors.surface : const Color(0xFFF7F9FC),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (isDark ? colors.surface : const Color(0xFFF7F9FC))
            .withOpacity(.84),
        hintStyle: TextStyle(color: colors.muted),
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
        hourMinuteTextColor: colors.ink,
        dayPeriodTextColor: colors.ink,
      ),
    );
  }
}
