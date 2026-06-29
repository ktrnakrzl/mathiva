# Mathiva Design System

Visual design reference for new screens/components. Companion to
`MATHIVA_FLUTTER_GUIDE.md` (folder structure, state management, repository
pattern) — that doc covers *how code is organized*, this one covers
*how things should look*.

**Scope: this is a reference for new work, not a redesign mandate.**
Existing screens (onboarding, login, register, home, chat, solution, image
solver, etc.) are not being reworked to match this retroactively. Two
points below were deliberately reconciled against what's already built
rather than taken at face value — see the "Reality check" notes.

## Design philosophy

Premium educational feel — think Duolingo/Notion/Linear/Khan Academy, not
playful or childish. Audience is 16–22 year old STEM students. Communicate:
intelligence, calmness, professionalism, simplicity, motivation to learn.

Style: modern glassmorphism/minimalist hybrid — rounded corners (16–24px),
soft shadows, large whitespace, smooth/subtle animations, clean typography,
elegant cards, consistent spacing, modern iconography.

## Color

**Reality check:** the app has a working 10-option palette switcher
(`AppPreferences.palette` → `lib/services/app_preferences.dart`), feeding
`ThemeData.colorScheme.fromSeed` in `lib/theme/app_theme.dart`. There is no
single fixed brand purple — every screen themes itself off whichever
palette the user has selected (default: "Pastel Purple", primary
`#7A3CFF`). Don't hard-code purple as *the* brand color; use
`AppPreferences.palette.value.primary`/`.secondary` (or `AppTheme.primaryOf
(context)`) so new components respect the active palette like everything
else does.

The non-brand tokens below are already exactly what's in use
(`lib/screens/login_screen.dart`, `register_screen.dart`, etc.) — confirmed,
not aspirational:

| Role | Value |
|---|---|
| Text Primary (`_ink`) | `#111827` |
| Text Secondary (`_muted`) | `#6B7280` |
| Border (`_border`) | `#E5E7EB` |
| Surface (`_surface`) | `#FFFFFF` |
| Background (`_pageBg`) | `#F8F9FB` |
| Success | `#22C55E` |
| Error | `#EF4444` |

Accent `#F59E0B` isn't currently used anywhere — fine to introduce for new
components that need a warm highlight (e.g. streak/XP counters), just don't
treat it as the primary brand color.

## Typography

`fontFamily: 'Poppins'` is already the global default (set in
`AppTheme.light()`), and both Poppins (300–900) and Inter (400–800) are
already bundled as app fonts (`pubspec.yaml`). Inter is not currently wired
as the default for anything — for new body text/descriptions/small labels,
set it explicitly: `TextStyle(fontFamily: 'Inter', ...)`. Use Poppins
(Bold/SemiBold/Medium) for headings and emphasis, matching the existing
per-screen heading styles.

## Buttons

**Reality check:** every primary/secondary button in the app today is
**outline-style** — transparent background, palette-colored border and
text, no fill (see `image_solver_screen.dart`'s `_ScanActionButton`:
"Minimal outline button. No fill, no shadow"). This was a deliberate,
consistent choice across every screen, not an oversight — keep using it for
new buttons rather than introducing filled buttons. Pattern: `OutlinedButton`
with `side: BorderSide(color: primary, width: 1)`, `backgroundColor:
Colors.transparent`, `borderRadius: BorderRadius.circular(13–16)`.

Text buttons (e.g. "Forgot password?", "Sign up"): no border, palette
primary color, no background — already the existing pattern.

## Cards

Already aligned with the spec's intent: `borderRadius` 16–20px, subtle
`BoxShadow` (`Color(0x08000000), blurRadius: 8–10, offset: Offset(0, 2-3)`),
white surface, comfortable padding (~20px). Reuse this exact shadow/radius
combination for new cards rather than inventing new values.

## Navigation

Bottom nav (`lib/widgets/mathiva_bottom_nav.dart`) already matches: rounded
(`circular(20)`), floats above the bottom edge via `SafeArea` margin, has an
animated selection chip. Reuse it — don't build a second bottom nav.

Top app bar: use the shared `MathivaAppBar`
(`lib/widgets/mathiva_app_bar.dart`) rather than a bespoke `AppBar` — it
already provides the minimal/no-heavy-border treatment, an icon badge, and
title/subtitle slots consistent across every screen that uses it. The
greeting/avatar/notification-bell pattern is specifically a Home/Dashboard
header concern, not something every screen's app bar needs.

## Animations

Use the existing shared wrappers rather than writing new animation code:
`FadeSlideIn` (entrance fade+slide, `lib/presentation/widgets/`),
`TapScale` (press feedback), `AnimatedBackground` (the floating gradient
blob backdrop already on every full-screen page). Keep animations subtle —
this is the existing convention, not a new constraint.

## Icons

Use Material Symbols Rounded (`Icons.*_rounded`) — already the convention
throughout the app.

## Progress components

Streaks, XP, mastery cards, heatmaps, completion percentages — these are
real features described in the spec that don't fully exist yet (some
screens are stubbed: `progress_overview_screen.dart`,
`subject_progress_screen.dart`, `topic_analytics_screen.dart`). When
building these out, follow the color/card/animation conventions above
rather than introducing a separate visual language for "progress" UI.

## AI Tutor & math rendering

Chat bubbles, typing indicator, and suggestion chips already exist
(`lib/screens/chat_screen.dart`). Math rendering is wired via `MathRenderer`
(`lib/core/utils/math_renderer.dart`, backed by `flutter_math_fork`) —
**never render an equation as plain `Text` when math content is detected**;
this is already enforced in `chat_screen.dart` and `solution_screen.dart` as
of this session. Markdown support, code blocks, and image attachments in
chat are not yet implemented.

## Accessibility

Touch targets ≥48dp, readable contrast, responsive layouts — generally
already true of existing screens (buttons are 50–56px tall). Dark mode and
tablet-specific layouts are not implemented yet (`AppPreferences.darkMode`
exists as a toggle but isn't wired to an actual dark `ThemeData`).

## Spacing

Use the 4/8/12/16/24/32/48 scale — this already matches the `SizedBox`
values used throughout existing screens. Keep using it for new spacing
rather than arbitrary values.

## Coding guidelines for new UI work

- Check `lib/widgets/`, `lib/presentation/widgets/`, and this doc's
  references before writing a new component — most primitives
  (buttons, cards, animations, nav, app bar) already exist.
- Follow the repository pattern in `MATHIVA_FLUTTER_GUIDE.md` for any new
  feature that talks to the backend; use Riverpod only for *new* features'
  DI (existing screens intentionally weren't migrated).
- Use `go_router` for navigation (already universal).
- "Compiles without warnings" is aspirational for new code, not a retroactive
  requirement — the codebase currently has ~358 pre-existing lint warnings
  (mostly deprecated `withOpacity` calls) that are a separate cleanup effort,
  not something every new PR needs to fix.
