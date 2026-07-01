import 'package:flutter/material.dart';

/// The neutral/chrome colors every screen needs (text, surfaces, borders,
/// accent) — as a [ThemeExtension] so they switch reactively between light and
/// dark instead of being duplicated as hardcoded `const Color` values in each
/// screen file. Screens read these via `AppTheme.colorsOf(context)`.
///
/// This is the shadcn/ui-style design system: a near-white/near-black canvas,
/// flat bordered cards, generous whitespace, and a single violet accent
/// (`#7C3AED`) that is identical in both light and dark modes — only surfaces,
/// borders, and text invert. All accent usages (buttons, active nav, progress
/// fills, icon-chip tints, badges) read from [accent] so the whole app can be
/// re-accented from one place.
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color ink; // text primary
  final Color muted; // text muted (secondary)
  final Color subtleMuted; // text faint (labels, timestamps)
  final Color border; // hairlines, card borders
  final Color surface; // card / panel surface
  final Color pageBg; // canvas / scaffold background
  final Color elevated; // hover / active raised state
  final Color chromeSurface; // opaque app-bar/nav fallback (== elevated)
  final Color chromeBorder; // (== border)
  final Color titleColor; // page-title text (== ink in shadcn)

  // Accent — the single cyan brand color, identical in both modes.
  final Color accent;
  final Color accentHover;
  final Color onAccent; // text/icon color on top of an accent fill
  final Color ring; // translucent accent tint behind icon chips
  final Color pillBg; // badge / pill background
  final Color pillText; // badge / pill text
  final Color track; // progress-bar track

  // Legacy glass tokens — kept (repointed to flat shadcn values) so any widget
  // still referencing them compiles and reads as a flat surface, not glass.
  final Color glassFillStart;
  final Color glassFillEnd;
  final Color glassBorder;
  final Color glassBorderSoft;
  final Color glassChipFill;

  const SemanticColors({
    required this.ink,
    required this.muted,
    required this.subtleMuted,
    required this.border,
    required this.surface,
    required this.pageBg,
    required this.elevated,
    required this.chromeSurface,
    required this.chromeBorder,
    required this.titleColor,
    required this.accent,
    required this.accentHover,
    required this.onAccent,
    required this.ring,
    required this.pillBg,
    required this.pillText,
    required this.track,
    required this.glassFillStart,
    required this.glassFillEnd,
    required this.glassBorder,
    required this.glassBorderSoft,
    required this.glassChipFill,
  });

  static const light = SemanticColors(
    ink: Color(0xFF09090B), // text primary
    muted: Color(0xFF52525B), // text muted
    subtleMuted: Color(0xFF71717A), // text faint
    border: Color(0xFFE4E4E7),
    surface: Color(0xFFFAFAFA),
    pageBg: Color(0xFFFFFFFF),
    elevated: Color(0xFFF0F0F1),
    chromeSurface: Color(0xFFF0F0F1),
    chromeBorder: Color(0xFFE4E4E7),
    titleColor: Color(0xFF09090B),
    accent: Color(0xFF7C3AED),
    accentHover: Color(0xFF6D28D9),
    onAccent: Color(0xFFFFFFFF),
    ring: Color(0x247C3AED), // violet @ 0.14
    pillBg: Color(0xFFF4F4F5),
    pillText: Color(0xFF3F3F46),
    track: Color(0xFFE9E9EC),
    glassFillStart: Color(0xFFFAFAFA),
    glassFillEnd: Color(0xFFFAFAFA),
    glassBorder: Color(0xFFE4E4E7),
    glassBorderSoft: Color(0xFFE4E4E7),
    glassChipFill: Color(0x247C3AED),
  );

  static const dark = SemanticColors(
    ink: Color(0xFFFAFAFA),
    muted: Color(0xFFA1A1AA),
    subtleMuted: Color(0xFF71717A),
    border: Color(0x14FFFFFF), // white @ 0.08
    surface: Color(0xFF101010),
    pageBg: Color(0xFF0A0A0A),
    elevated: Color(0xFF1A1A1A),
    chromeSurface: Color(0xFF1A1A1A),
    chromeBorder: Color(0x14FFFFFF),
    titleColor: Color(0xFFFAFAFA),
    accent: Color(0xFF7C3AED),
    accentHover: Color(0xFF9E7BFF),
    onAccent: Color(0xFFFFFFFF),
    ring: Color(0x387C3AED), // violet @ 0.22
    pillBg: Color(0xFF1C1C1C),
    pillText: Color(0xFFE4E4E7),
    track: Color(0xFF1F1F1F),
    glassFillStart: Color(0xFF101010),
    glassFillEnd: Color(0xFF101010),
    glassBorder: Color(0x14FFFFFF),
    glassBorderSoft: Color(0x14FFFFFF),
    glassChipFill: Color(0x387C3AED),
  );

  @override
  SemanticColors copyWith({
    Color? ink,
    Color? muted,
    Color? subtleMuted,
    Color? border,
    Color? surface,
    Color? pageBg,
    Color? elevated,
    Color? chromeSurface,
    Color? chromeBorder,
    Color? titleColor,
    Color? accent,
    Color? accentHover,
    Color? onAccent,
    Color? ring,
    Color? pillBg,
    Color? pillText,
    Color? track,
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
      elevated: elevated ?? this.elevated,
      chromeSurface: chromeSurface ?? this.chromeSurface,
      chromeBorder: chromeBorder ?? this.chromeBorder,
      titleColor: titleColor ?? this.titleColor,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      onAccent: onAccent ?? this.onAccent,
      ring: ring ?? this.ring,
      pillBg: pillBg ?? this.pillBg,
      pillText: pillText ?? this.pillText,
      track: track ?? this.track,
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
      elevated: Color.lerp(elevated, other.elevated, t)!,
      chromeSurface: Color.lerp(chromeSurface, other.chromeSurface, t)!,
      chromeBorder: Color.lerp(chromeBorder, other.chromeBorder, t)!,
      titleColor: Color.lerp(titleColor, other.titleColor, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      pillBg: Color.lerp(pillBg, other.pillBg, t)!,
      pillText: Color.lerp(pillText, other.pillText, t)!,
      track: Color.lerp(track, other.track, t)!,
      glassFillStart: Color.lerp(glassFillStart, other.glassFillStart, t)!,
      glassFillEnd: Color.lerp(glassFillEnd, other.glassFillEnd, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBorderSoft: Color.lerp(glassBorderSoft, other.glassBorderSoft, t)!,
      glassChipFill: Color.lerp(glassChipFill, other.glassChipFill, t)!,
    );
  }
}
