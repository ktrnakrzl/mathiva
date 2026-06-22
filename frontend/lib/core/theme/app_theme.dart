import 'package:flutter/material.dart';
import 'package:mathiva/core/constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FF),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w400),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w400),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: .92),
        elevation: 3,
        shadowColor: AppColors.primary.withValues(alpha: .08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

// Enhanced UI patch placeholder: softer typography, smoother cards, transitions.
