import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../utils/progress_calc.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../presentation/widgets/tap_scale.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ProgressStore.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = LocalContentService().getSubjects();
    final firstSubject = subjects.first;
    final firstTopic = firstSubject.topics.first;
    final firstLesson = firstTopic.lessons.first;
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.pageBg,
      // Frosted-glass header — BackdropFilter blur over a translucent white
      // tint, matching GlassCard/MathivaBottomNav, instead of the old flat
      // lavender chrome.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: colors.glassFillStart,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 1,
              shadowColor: Colors.black.withOpacity(0.08),
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
                  Text(
                    'Mathivia',
                    style: TextStyle(
                      color: colors.titleColor,
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
                    color: primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: colors.glassBorder,
                ),
              ),
            ),
          ),
        ),
      ),
      body: AnimatedBackground(
        vivid: true,
        child: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              // ① Greeting + stats strip (streak/points/mastery are all
              // reactive on real attempt history via ProgressStore).
              const FadeSlideIn(
                child: _GreetingHeader(),
              ),
              const SizedBox(height: 20),

              // ② Continue Learning — progress badge reflects real mastery of
              // the focus topic, recomputed whenever ProgressStore updates.
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: ValueListenableBuilder<UserProgress?>(
                  valueListenable: ProgressStore.current,
                  builder: (context, progress, _) {
                    final byConcept = progress?.conceptStats ?? const {};
                    final pct =
                        (topicProgress(firstTopic, byConcept) * 100).round();
                    return _ContinueLearningHero(
                      subject: firstSubject.title,
                      lesson: firstLesson.title,
                      progress: pct,
                      onTap: () => context.push(
                        RouteNames.lessonDetail,
                        extra: {
                          'subjectId': firstSubject.id,
                          'topicId': firstTopic.id,
                          'lessonId': firstLesson.id,
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ③ What would you like to do?
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
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

// ─── Greeting Header ──────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Compact "1.2k" style for large point totals, exact for small ones.
  static String _formatPoints(int points) {
    if (points >= 1000) return '${(points / 1000).toStringAsFixed(1)}k';
    return '$points';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: AppPreferences.studentName,
          builder: (context, name, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Streak / points / mastery all derive from real attempt history.
        // Before the first fetch resolves (or for a brand-new user) they
        // simply read as 0 — no fake fallback values.
        ValueListenableBuilder<UserProgress?>(
          valueListenable: ProgressStore.current,
          builder: (context, progress, _) {
            final byConcept = progress?.conceptStats ?? const {};
            final allTopics = LocalContentService().allTopics();
            final mastery = allTopics.isEmpty
                ? 0
                : (allTopics
                            .map((t) => topicProgress(t, byConcept) * 100)
                            .reduce((a, b) => a + b) /
                        allTopics.length)
                    .round();

            return Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.local_fire_department_rounded,
                    value: '${progress?.currentStreakDays ?? 0}',
                    label: 'day streak',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    icon: Icons.star_rounded,
                    value: _formatPoints(progress?.points ?? 0),
                    label: 'points',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    icon: Icons.insights_rounded,
                    value: '$mastery%',
                    label: 'mastery',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: BorderRadius.circular(14),
      blurSigma: 14,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final colors = AppTheme.colorsOf(context);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              'What would you like to do?',
              style: TextStyle(
                color: colors.muted,
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                      color: colors.glassBorderSoft, height: 1, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Recent',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                      color: colors.glassBorderSoft, height: 1, thickness: 1),
                ),
              ],
            ),
          ),
          // NOTE: these two "Recent" rows are still illustrative placeholders.
          // They represent *scan/solver* history, which has no persistence
          // layer at all yet (a separate feature from quiz/practice progress,
          // out of scope for the stats work that made streak/points/mastery
          // above real). Left as static examples until solver history exists.
          _RecentScanRow(
            title: '2x² + 5x + 3 = 0',
            subtitle: 'Quadratic equation · solved today',
            onTap: onScan1Tap,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Divider(
                color: colors.glassBorderSoft, height: 1, thickness: 1),
          ),
          _RecentScanRow(
            title: 'f(x) = 2x + 1',
            subtitle: 'Functions · reviewed yesterday',
            onTap: onScan2Tap,
            isLast: true,
          ),
        ],
      ),
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
    final colors = AppTheme.colorsOf(context);

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
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.muted, size: 17),
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
    final colors = AppTheme.colorsOf(context);

    return GlassCard(
      onTap: onTap,
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
                child:
                    Icon(Icons.auto_awesome_rounded, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Focus",
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject,
                      style: TextStyle(color: colors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    backgroundColor: colors.glassBorderSoft,
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
    final colors = AppTheme.colorsOf(context);

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
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.muted,
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
    final colors = AppTheme.colorsOf(context);

    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.glassChipFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.glassBorder, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: colors.ink,
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
