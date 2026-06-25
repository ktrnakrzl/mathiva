import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/tap_scale.dart';
import '../presentation/widgets/app_card.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _pageBg = Color(0xFFF8F9FB);

// Shared app-chrome surface — a very light lavender tint used by the header
// (and mirrored in MathivaBottomNav) so both pieces of app chrome read as
// one distinct layer, sitting just above the white content surfaces below.
const _chromeSurface = Color(0xFFF6F5FB);
const _chromeBorder = Color(0xFFEAE8F5);

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
      // No explicit backgroundColor — the Scaffold now inherits AppTheme's
      // scaffoldBackgroundColor, which is the active palette's faint tint.
      // Switching palettes (Settings) recolors this screen automatically.
      appBar: AppBar(
        backgroundColor: _chromeSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.04),
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 58,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/mathiva_logo.png',
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'Mathivia',
              style: TextStyle(
                color: Color(0xFF312E81),
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                height: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ask Math Tutor',
            onPressed: () => context.push(RouteNames.chat),
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppPreferences.palette.value.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _chromeBorder,
          ),
        ),
      ),
      body: AnimatedBackground(
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