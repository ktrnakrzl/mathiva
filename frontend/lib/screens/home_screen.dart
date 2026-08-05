import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../services/scan_history_service.dart';
import '../utils/progress_calc.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';
import '../presentation/widgets/animated_background.dart';
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

  /// Ask the server what to review next -- a concept the student has been
  /// missing -- and jump straight into adaptive practice on it, or tell them
  /// they're caught up.
  Future<void> _startReview() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Finding what to review…'),
      duration: Duration(milliseconds: 800),
    ));
    try {
      final target = await ProgressService.fetchReviewNext(
        LocalContentService().allConceptsWithContext(),
      );
      if (!mounted) return;
      if (!target.available) {
        messenger.showSnackBar(const SnackBar(
          content: Text("You're all caught up — nothing to review right now."),
        ));
        return;
      }
      context.push(RouteNames.practice, extra: {
        'subjectId': target.subjectId,
        'topicId': target.topicId,
        'lessonId': target.lessonId,
        'conceptId': target.conceptId,
        'candidateConcepts': [target.conceptId],
      });
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content:
            Text("Couldn't start review. Check your connection and try again."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = LocalContentService().getSubjects();
    final firstSubject = subjects.first;
    final firstTopic = firstSubject.topics.first;
    final firstLesson = firstTopic.lessons.first;
    final practiceCatalog = LocalContentService().allConceptsWithContext();
    final firstPracticeContext = practiceCatalog.first;
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.pageBg,
      appBar: const MathivaTopBar(),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 108),
            children: [
              const _GreetingHeader(),
              const SizedBox(height: 18),

              // Stats strip — streak/points/mastery from real attempt history.
              const _StatsStrip(),

              const _GroupLabel("Today's Focus"),
              ValueListenableBuilder<UserProgress?>(
                valueListenable: ProgressStore.current,
                builder: (context, progress, _) {
                  final byConcept = progress?.conceptStats ?? const {};
                  final pct =
                      (topicProgress(firstTopic, byConcept) * 100).round();
                  return _FocusCard(
                    subject: firstSubject.title,
                    lesson: firstLesson.title,
                    meta: 'Lesson 1 · ${firstTopic.title}',
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

              const _GroupLabel('What would you like to do?'),
              _ScanHero(onTap: () => context.push(RouteNames.imageSolver)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      label: 'Practice',
                      icon: Icons.fitness_center_rounded,
                      onTap: () => context.push(
                        RouteNames.practice,
                        extra: {
                          'subjectId': firstPracticeContext['subject_id'],
                          'topicId': firstPracticeContext['topic_id'],
                          'lessonId': firstPracticeContext['lesson_id'],
                          'conceptId': firstPracticeContext['concept_id'],
                          'candidateConceptContexts': practiceCatalog,
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      label: 'Review',
                      icon: Icons.refresh_rounded,
                      onTap: _startReview,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      label: 'Progress',
                      icon: Icons.bar_chart_rounded,
                      onTap: () => context.push(RouteNames.progress),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      label: 'Awards',
                      icon: Icons.emoji_events_rounded,
                      onTap: () =>
                          context.push(RouteNames.progress, extra: true),
                    ),
                  ),
                ],
              ),

              // "Recent" = the student's real, on-device solved-scan history
              // (ScanHistoryService). Hidden entirely until they've solved at
              // least one scan, so a new user never sees fabricated activity.
              ValueListenableBuilder<List<ScanHistoryEntry>>(
                valueListenable: ScanHistoryService.recent,
                builder: (context, entries, _) {
                  if (entries.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RecentDivider(),
                      for (final entry in entries)
                        _RecentScanRow(
                          title: _stripMathDelimiters(entry.question),
                          subtitle: 'Solved ${_relativeTime(entry.solvedAt)}',
                          onTap: () => context.push(
                            RouteNames.solution,
                            extra: entry.toProblem(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.home),
    );
  }
}

// ─── Group label ────────────────────────────────────────────────────────────
class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 2, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: colors.subtleMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06 * 12,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ValueListenableBuilder<String>(
      valueListenable: AppPreferences.studentName,
      builder: (context, name, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greeting()},',
              style: TextStyle(
                color: colors.subtleMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: AppTheme.serif(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.ink,
                height: 1.05,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Stats strip ──────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  /// Compact "1.2k" style for large point totals, exact for small ones.
  static String _formatPoints(int points) {
    if (points >= 1000) return '${(points / 1000).toStringAsFixed(1)}k';
    return '$points';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProgress?>(
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
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                value: '${progress?.currentStreakDays ?? 0}',
                label: 'Day Streak',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                value: _formatPoints(progress?.points ?? 0),
                label: 'Points',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.track_changes_rounded,
                value: '$mastery%',
                label: 'Mastery',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconChip(icon: icon, size: 30, radius: 9, iconSize: 17),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02 * 20,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.subtleMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable accent-tinted icon chip ───────────────────────────────────────
class _IconChip extends StatelessWidget {
  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;

  const _IconChip({
    required this.icon,
    this.size = 42,
    this.radius = 12,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.ring,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: colors.accent, size: iconSize),
    );
  }
}

// ─── Today's Focus card ─────────────────────────────────────────────────────
class _FocusCard extends StatelessWidget {
  final String subject;
  final String lesson;
  final String meta;
  final int progress;
  final VoidCallback onTap;

  const _FocusCard({
    required this.subject,
    required this.lesson,
    required this.meta,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconChip(icon: Icons.calculate_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: TextStyle(color: colors.subtleMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Pill('$progress%'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: colors.track,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
          const SizedBox(height: 16),
          _AccentButton(label: 'Continue', onTap: onTap),
        ],
      ),
    );
  }
}

// ─── Pill / badge ───────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.pillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.pillText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── Full-width accent button ───────────────────────────────────────────────
class _AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AccentButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.onAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: colors.onAccent, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── "Scan a Problem" hero ──────────────────────────────────────────────────
class _ScanHero extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withOpacity(0.35),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.center_focus_strong_rounded,
                  color: colors.onAccent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan a Problem',
                    style: TextStyle(
                      color: colors.onAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Solve any equation instantly',
                    style: TextStyle(
                      color: colors.onAccent.withOpacity(0.82),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Secondary action tile ──────────────────────────────────────────────────
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
    final colors = AppTheme.colorsOf(context);
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconChip(icon: icon, size: 38, radius: 11, iconSize: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The backend returns the detected equation wrapped for math rendering, e.g.
// "\(2x + 3 = 13\)". The Recent row shows it as a compact plain-text label, so
// strip the \( \) / \[ \] delimiters.
String _stripMathDelimiters(String s) {
  var t = s.trim();
  for (final pair in const [
    ['\\(', '\\)'],
    ['\\[', '\\]'],
    [r'$$', r'$$'],
    [r'$', r'$'],
  ]) {
    if (t.startsWith(pair[0]) &&
        t.endsWith(pair[1]) &&
        t.length > pair[0].length + pair[1].length) {
      t = t.substring(pair[0].length, t.length - pair[1].length).trim();
      break;
    }
  }
  return t.isEmpty ? s.trim() : t;
}

// Human-friendly "when" for a recent scan, e.g. "just now", "5m ago",
// "2h ago", "yesterday", "3d ago", or a date for anything older.
String _relativeTime(DateTime when) {
  final d = DateTime.now().difference(when);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'yesterday';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';
}

// ─── Recent divider ─────────────────────────────────────────────────────────
class _RecentDivider extends StatelessWidget {
  const _RecentDivider();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 2, 6),
      child: Row(
        children: [
          Text(
            'Recent',
            style: TextStyle(
              color: colors.subtleMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06 * 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Divider(color: colors.border, height: 1, thickness: 1)),
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

  const _RecentScanRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _IconChip(
                icon: Icons.functions_rounded,
                size: 38,
                radius: 11,
                iconSize: 18),
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
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.subtleMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: colors.subtleMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
