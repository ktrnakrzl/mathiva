import 'package:flutter/material.dart';
import '../services/app_preferences.dart';
import 'semantic_colors.dart';

class AppColors {
  static const purple = Color(0xFF7C3AED);
  static const violet = Color(0xFF7C3AED);
  static const pink = Color(0xFF7C3AED);
  static const orange = Color(0xFF7C3AED);
  static const sky = Color(0xFFFFFFFF);
  static const blush = Color(0xFFFFFFFF);
  static const ink = Color(0xFF09090B);
  static const muted = Color(0xFF52525B);
}

class AppTheme {
  static MathiviaPalette paletteOf(BuildContext context) =>
      AppPreferences.palette.value;

  /// The single accent color (cyan) — read from [SemanticColors] so the whole
  /// app re-accents from one place. Screens that call `AppTheme.primaryOf`
  /// now get the shadcn accent, not the old palette hue.
  static Color primaryOf(BuildContext context) => colorsOf(context).accent;
  static Color secondaryOf(BuildContext context) =>
      colorsOf(context).accentHover;
  static List<Color> backgroundOf(BuildContext context) =>
      [colorsOf(context).pageBg, colorsOf(context).pageBg];

  /// The reactive light/dark neutral palette — read this instead of
  /// declaring local `_ink`/`_muted`/`_pageBg` consts in a screen.
  static SemanticColors colorsOf(BuildContext context) =>
      Theme.of(context).extension<SemanticColors>()!;

  /// The app-wide **headline** typeface (Fraunces serif) — the same display
  /// serif used on the auth flow. Centralized here so every headline (page /
  /// section titles, the home greeting name, detail-screen app-bar titles)
  /// reads from one place and the whole app's headline font can be swapped by
  /// editing this single method.
  static TextStyle serif({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static ThemeData light([MathiviaPalette? palette]) =>
      _build(Brightness.light, SemanticColors.light);

  static ThemeData dark([MathiviaPalette? palette]) =>
      _build(Brightness.dark, SemanticColors.dark);

  static ThemeData _build(Brightness brightness, SemanticColors colors) {
    final accent = colors.accent;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: colors.pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: accent,
        surface: colors.surface,
        brightness: brightness,
      ).copyWith(
        onPrimary: colors.onAccent,
        outline: colors.border,
      ),
      extensions: [colors],
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? Colors.white : null),
        trackColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? accent : colors.track),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? accent : null),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.ink,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.subtleMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: accent,
        contentTextStyle:
            TextStyle(color: colors.onAccent, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      timePickerTheme: TimePickerThemeData(
        dialHandColor: accent,
        hourMinuteTextColor: colors.ink,
        dayPeriodTextColor: colors.ink,
      ),
    );
  }
}
