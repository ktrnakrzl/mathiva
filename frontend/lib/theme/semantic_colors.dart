import 'package:flutter/material.dart';

/// The neutral/chrome colors every screen needs (text, surfaces, borders,
/// glass tints) — as a [ThemeExtension] so they switch reactively between
/// light and dark instead of being duplicated as hardcoded `const Color`
/// values in each screen file. Screens read these via
/// `AppTheme.colorsOf(context)` instead of declaring their own `_ink`,
/// `_muted`, `_pageBg`, etc.
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color ink; // primary text
  final Color muted; // secondary text / captions
  final Color subtleMuted; // placeholder text, dimmer captions, idle icons
  final Color border; // hairlines, opaque card borders
  final Color surface; // opaque card background (non-glass)
  final Color pageBg; // scaffold / animated-background base
  final Color chromeSurface; // opaque app-bar/nav fallback (e.g. crop screen)
  final Color chromeBorder;
  final Color titleColor; // branded page-title accent (was hardcoded indigo)

  // Glass tokens — feed GlassCard/MathivaAppBar/MathivaBottomNav so the
  // frosted-glass look itself adapts: dark mode uses a much lower-opacity
  // white tint (a bright tint at light-mode opacity would wash out a dark
  // blurred background instead of reading as "frosted").
  final Color glassFillStart;
  final Color glassFillEnd;
  final Color glassBorder; // strong border / hairline dividers
  final Color glassBorderSoft; // in-card dividers, progress track background
  final Color glassChipFill; // translucent tile fills (e.g. ActionTile)

  const SemanticColors({
    required this.ink,
    required this.muted,
    required this.subtleMuted,
    required this.border,
    required this.surface,
    required this.pageBg,
    required this.chromeSurface,
    required this.chromeBorder,
    required this.titleColor,
    required this.glassFillStart,
    required this.glassFillEnd,
    required this.glassBorder,
    required this.glassBorderSoft,
    required this.glassChipFill,
  });

  static const light = SemanticColors(
    ink: Color(0xFF111827),
    muted: Color(0xFF4B5563), // darker grey — readable over light glass/color bg
    subtleMuted: Color(0xFF6B7280), // was 9CA3AF (too faint to read on light mode)
    border: Color(0xFFE5E7EB),
    surface: Colors.white,
    pageBg: Color(0xFFF8F9FB),
    chromeSurface: Color(0xFFF6F5FB),
    chromeBorder: Color(0xFFEAE8F5),
    titleColor: Color(0xFF312E81),
    glassFillStart: Color(0x0FFFFFFF), // white @ 0.06 — lighter, airier glass
    glassFillEnd: Color(0x03FFFFFF), // white @ 0.012 — nearly clear at the bottom
    glassBorder: Color(0xA6FFFFFF), // white @ 0.65 — crisp specular rim (Apple)
    glassBorderSoft: Color(0x66FFFFFF), // white @ 0.4
    glassChipFill: Color(0x59FFFFFF), // white @ 0.35
  );

  static const dark = SemanticColors(
    ink: Color(0xFFF1F2F6),
    muted: Color(0xFF9CA3B5),
    subtleMuted: Color(0xFF6B7280),
    border: Color(0xFF31354A),
    surface: Color(0xFF1B1E2C),
    pageBg: Color(0xFF09090C), // near-black base (was navy 0xFF11131C)
    chromeSurface: Color(0xFF1E2030),
    chromeBorder: Color(0xFF2A2D40),
    titleColor: Color(0xFFC7C5FF),
    glassFillStart: Color(0x0DFFFFFF), // white @ 0.05 — lighter, airier glass
    glassFillEnd: Color(0x03FFFFFF), // white @ 0.012 — nearly clear at the bottom
    glassBorder: Color(0x52FFFFFF), // white @ 0.32 — specular rim (Apple, dark)
    glassBorderSoft: Color(0x1FFFFFFF), // white @ 0.12
    glassChipFill: Color(0x1AFFFFFF), // white @ 0.10
  );

  @override
  SemanticColors copyWith({
    Color? ink,
    Color? muted,
    Color? subtleMuted,
    Color? border,
    Color? surface,
    Color? pageBg,
    Color? chromeSurface,
    Color? chromeBorder,
    Color? titleColor,
    Color? glassFillStart,
    Color? glassFillEnd,
    Color? glassBorder,
    Color? glassBorderSoft,
    Color? glassChipFill,
  }) {
    return SemanticColors(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      subtleMuted: subtleMuted ?? this.subtleMuted,
      border: border ?? this.border,
      surface: surface ?? this.surface,
      pageBg: pageBg ?? this.pageBg,
      chromeSurface: chromeSurface ?? this.chromeSurface,
      chromeBorder: chromeBorder ?? this.chromeBorder,
      titleColor: titleColor ?? this.titleColor,
      glassFillStart: glassFillStart ?? this.glassFillStart,
      glassFillEnd: glassFillEnd ?? this.glassFillEnd,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBorderSoft: glassBorderSoft ?? this.glassBorderSoft,
      glassChipFill: glassChipFill ?? this.glassChipFill,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtleMuted: Color.lerp(subtleMuted, other.subtleMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
      chromeSurface: Color.lerp(chromeSurface, other.chromeSurface, t)!,
      chromeBorder: Color.lerp(chromeBorder, other.chromeBorder, t)!,
      titleColor: Color.lerp(titleColor, other.titleColor, t)!,
      glassFillStart: Color.lerp(glassFillStart, other.glassFillStart, t)!,
      glassFillEnd: Color.lerp(glassFillEnd, other.glassFillEnd, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBorderSoft: Color.lerp(glassBorderSoft, other.glassBorderSoft, t)!,
      glassChipFill: Color.lerp(glassChipFill, other.glassChipFill, t)!,
    );
  }
}
