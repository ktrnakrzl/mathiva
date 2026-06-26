import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
// Swapped from AnimatedBackground (moving palette blobs) to
// AtmosphereBackground (the static painted gradient + soft orbs used by
// onboarding/login/register) so Home visually continues the auth flow
// instead of cutting to a different background treatment. AppCard's white
// surfaces sit on top of this and naturally mute it, which keeps the effect
// subtle rather than as strong as it reads on the auth screens.
import '../presentation/widgets/atmosphere_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/tap_scale.dart';
import '../presentation/widgets/app_card.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _pageBg = Color(0xFFF8F9FB);

// Solid, subtle lavender tint for the header — replaces the previous
// translucent glass surface entirely. No blur, no glassmorphism: just a
// flat, premium-minimal color that softly echoes the purple atmosphere
// without competing with it.
const _headerTint = Color(0xFFF6F2FF);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = LocalContentService().getSubjects();
    final firstSubject = subjects.first;
    final firstTopic = firstSubject.topics.first;
    final firstLesson = firstTopic.lessons.first;

    return Scaffold(
      extendBody: true,
      // No explicit backgroundColor — the Scaffold inherits AppTheme's
      // scaffoldBackgroundColor, which is the active palette's faint tint.
      // Switching palettes (Settings) recolors this screen automatically.

      // ── Header ────────────────────────────────────────────────────────────
      // No glassmorphism, no blur — a flat, solid lavender tint
      // (Color(0xFFF6F2FF)) instead. Height unchanged at 56 px. Just the
      // logo, wordmark, and chat action; only a hairline-level shadow
      // appears once content scrolls underneath, nothing large or dramatic.
      appBar: AppBar(
        backgroundColor: _headerTint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 56,
        titleSpacing: 22,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/mathiva_logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'Mathivia',
              style: TextStyle(
                color: Color(0xFF312E81),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                height: 1,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _HeaderIconAction(
              icon: Icons.chat_bubble_outline_rounded,
              tooltip: 'Ask Math Tutor',
              onTap: () => context.push(RouteNames.chat),
            ),
          ),
        ],
      ),
      body: AtmosphereBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              // ① Continue Learning
              FadeSlideIn(
                child: _ContinueLearningHero(
                  subject: firstSubject.title,
                  lesson: firstLesson.title,
                  progress: firstTopic.progress,
                  onTap: () => context.push(
                    RouteNames.lessonDetail,
                    extra: {
                      'subjectId': firstSubject.id,
                      'topicId': firstTopic.id,
                      'lessonId': firstLesson.id,
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ② What would you like to do?
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _NextActionsZone(
                  onScanTap: () => context.push(RouteNames.imageSolver),
                  onPracticeTap: () => context.push(
                    RouteNames.lessons,
                    extra: {'subjectId': firstSubject.id},
                  ),
                  onProgressTap: () => context.push(RouteNames.progress),
                  onAwardsTap: () =>
                      context.push(RouteNames.progress, extra: true),
                  onScan1Tap: () => context.push(RouteNames.solution),
                  onScan2Tap: () => context.push(
                    RouteNames.concept,
                    extra: {
                      'subjectId': firstSubject.id,
                      'topicId': firstTopic.id,
                      'lessonId': firstLesson.id,
                      'conceptId': firstLesson.concepts.first.id,
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.home),
    );
  }
}

// ─── Header Icon Action ───────────────────────────────────────────────────
// Gives app-bar actions the same soft, tinted icon-container treatment used
// throughout Home (action tiles, recent rows, the focus card) instead of a
// bare IconButton, so the header reads as part of the same component
// family as the content below it rather than generic Material chrome.

class _HeaderIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return TapScale(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 19),
        ),
      ),
    );
  }
}

// ─── Next Actions Zone ────────────────────────────────────────────────────────

class _NextActionsZone extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onPracticeTap;
  final VoidCallback onProgressTap;
  final VoidCallback onAwardsTap;
  final VoidCallback onScan1Tap;
  final VoidCallback onScan2Tap;

  const _NextActionsZone({
    required this.onScanTap,
    required this.onPracticeTap,
    required this.onProgressTap,
    required this.onAwardsTap,
    required this.onScan1Tap,
    required this.onScan2Tap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1 — What would you like to do?
        AppCard.flat(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Text(
                  'What would you like to do?',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _PrimaryActionTile(
                  label: 'Scan a Problem',
                  description: 'Solve any equation instantly',
                  icon: Icons.document_scanner_rounded,
                  onTap: onScanTap,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        label: 'Practice',
                        icon: Icons.edit_note_rounded,
                        onTap: onPracticeTap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        label: 'Progress',
                        icon: Icons.trending_up_rounded,
                        onTap: onProgressTap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        label: 'Awards',
                        icon: Icons.emoji_events_rounded,
                        onTap: onAwardsTap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Card 2 — Recent
        AppCard.flat(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(color: _border, height: 1, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Recent',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: _border, height: 1, thickness: 1),
                    ),
                  ],
                ),
              ),
              _RecentScanRow(
                title: '2x² + 5x + 3 = 0',
                subtitle: 'Quadratic equation · solved today',
                onTap: onScan1Tap,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Divider(color: _border, height: 1, thickness: 1),
              ),
              _RecentScanRow(
                title: 'f(x) = 2x + 1',
                subtitle: 'Functions · reviewed yesterday',
                onTap: onScan2Tap,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Recent Scan Row ──────────────────────────────────────────────────────────

class _RecentScanRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _RecentScanRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, isLast ? 14 : 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.functions_rounded, color: primary, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Continue Learning Hero ───────────────────────────────────────────────────

class _ContinueLearningHero extends StatelessWidget {
  final String subject;
  final String lesson;
  final int progress;
  final VoidCallback onTap;

  const _ContinueLearningHero({
    required this.subject,
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return TapScale(
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Focus",
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lesson,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subject,
                        style: const TextStyle(color: _muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withOpacity(0.12)),
                  ),
                  child: Text(
                    '$progress%',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: _border,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Continue',
                  style: TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded, color: primary, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Primary Action Tile (Scan) ───────────────────────────────────────────────

class _PrimaryActionTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.18), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                color: primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: primary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pageBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}