import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../utils/progress_calc.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../theme/app_theme.dart';

class ProgressOverviewScreen extends StatefulWidget {
  final bool scrollToAchievements;

  /// When true, renders only the scrollable progress body (no Scaffold, top
  /// bar or bottom nav) so it can be embedded as a segment inside the merged
  /// "Learn" tab. Standalone (pushed) use keeps the full shell.
  final bool embedded;
  const ProgressOverviewScreen({
    super.key,
    this.scrollToAchievements = false,
    this.embedded = false,
  });

  @override
  State<ProgressOverviewScreen> createState() => _ProgressOverviewScreenState();
}

class _ProgressOverviewScreenState extends State<ProgressOverviewScreen> {
  final _scrollController = ScrollController();
  final _achievementsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ProgressStore.refresh();
    if (widget.scrollToAchievements) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          final ctx = _achievementsKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              alignment: 0.0,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);
    final subjects = LocalContentService().getSubjects();
    final topics = subjects.expand((s) => s.topics).toList();
    final embedded = widget.embedded;

    final content = ValueListenableBuilder<UserProgress?>(
      valueListenable: ProgressStore.current,
      builder: (context, progress, _) {
        final byConcept = progress?.conceptStats ?? const {};
        return ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(18, embedded ? 4 : 22, 18, 112),
          children: [
                  // Page title (lives in the body, not the top bar). When
                  // embedded inside the "Learn" tab the segmented control
                  // supplies the heading, so it's omitted here.
                  if (!embedded)
                    FadeSlideIn(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          'Progress',
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  // ── Stat cards ─────────────────────────────────────────────
                  // Wrapped in IntrinsicHeight so all three Expanded cards share
                  // the height of whichever one is tallest. Without this, each
                  // card sized itself independently — and since "Problems
                  // Solved" wraps to two lines while "Accuracy"/"Streak Days"
                  // stay on one, that card alone grew taller than its siblings.
                  FadeSlideIn(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Problems Solved',
                              value: '${progress?.totalAttempts ?? 0}',
                              icon: Icons.check_circle_outline_rounded,
                              primary: primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Accuracy',
                              value:
                                  '${(progress?.overallAccuracy ?? 0).round()}%',
                              icon: Icons.track_changes_rounded,
                              primary: primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Streak Days',
                              value: '${progress?.currentStreakDays ?? 0}',
                              icon: Icons.local_fire_department_rounded,
                              primary: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Weekly activity card ────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'Weekly Activity'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: _WeeklyLineChart(
                              primary: primary,
                              days: progress?.last7Days ?? const [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Topic Mastery label ─────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _SectionLabel(label: 'Topic Mastery'),
                    ),
                  ),

                  // ── Topic mastery rows ──────────────────────────────────────
                  ...topics.asMap().entries.map((entry) {
                    final i = entry.key;
                    final topic = entry.value;
                    final subjectId =
                        subjects.firstWhere((s) => s.topics.contains(topic)).id;
                    final topicPct =
                        (topicProgress(topic, byConcept) * 100).round();
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 120 + 50 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TopicMasteryCard(
                          topic: topic,
                          primary: primary,
                          progressPercent: topicPct,
                          onTap: () => context.push(
                            RouteNames.topicAnalytics,
                            extra: {
                              'subjectId': subjectId,
                              'topicId': topic.id,
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // ── Achievements label ──────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: Padding(
                      key: _achievementsKey,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: const _SectionLabel(label: 'Achievements'),
                    ),
                  ),

                  // ── Achievements grid ───────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: _AchievementsGrid(
                      primary: primary,
                      achievements: progress?.achievements ?? const [],
                    ),
                  ),
                ],
              );
      },
    );

    // Embedded: caller (LearnScreen) owns the shell.
    if (embedded) return content;

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.pageBg,
      appBar: const MathivaTopBar(),
      body: AnimatedBackground(
        vivid: true,
        child: SafeArea(top: false, child: content),
      ),
      bottomNavigationBar:
          const MathivaBottomNav(selected: MathivaTab.learn),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color primary;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: colors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

// ── Topic Mastery Card ────────────────────────────────────────────────────────

class _TopicMasteryCard extends StatelessWidget {
  final dynamic topic;
  final Color primary;
  final int progressPercent; // real mastery %, computed from attempt history
  final VoidCallback onTap;

  const _TopicMasteryCard({
    required this.topic,
    required this.primary,
    required this.progressPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = progressPercent.toDouble();
    final colors = AppTheme.colorsOf(context);

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic.title,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withOpacity(0.12)),
                ),
                child: Text(
                  '$progressPercent%',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: colors.muted, size: 15),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: colors.glassBorderSoft,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Line Chart ─────────────────────────────────────────────────────────

class _WeeklyLineChart extends StatelessWidget {
  final Color primary;
  final List<DayActivity> days;
  const _WeeklyLineChart({required this.primary, required this.days});

  // Single-letter weekday label derived from a "YYYY-MM-DD" date string, so
  // the axis tracks the actual 7 days returned rather than assuming a fixed
  // week-start. Falls back to an empty label if the date can't be parsed.
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _label(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return '';
    return _weekdayLetters[parsed.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    // Attempt counts in chronological order (oldest→newest), normalized in the
    // painter. Empty until the first fetch resolves → flat zero line.
    final counts = days.map((d) => d.attempts.toDouble()).toList();

    return CustomPaint(
      painter: _WeeklyLinePainter(
        primary: primary,
        gridColor: colors.border,
        values: counts,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (days.isEmpty)
                for (final l in _weekdayLetters)
                  Text(l, style: TextStyle(color: colors.muted, fontSize: 11))
              else
                for (final d in days)
                  Text(_label(d.date),
                      style: TextStyle(color: colors.muted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyLinePainter extends CustomPainter {
  final Color primary;
  final Color gridColor;
  final List<double> values;
  const _WeeklyLinePainter({
    required this.primary,
    required this.gridColor,
    required this.values,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Normalize raw attempt counts to 0..1 against the week's peak so the line
    // fills the chart regardless of absolute volume. No activity → flat line
    // along the baseline.
    final raw = values.isEmpty ? List<double>.filled(7, 0) : values;
    final peak = raw.fold<double>(0, (m, v) => v > m ? v : m);
    final normalized =
        peak <= 0 ? raw.map((_) => 0.0).toList() : raw.map((v) => v / peak).toList();
    final chartHeight = size.height - 26;
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < normalized.length; i++) {
      final x = i * (size.width / (normalized.length - 1));
      final y = chartHeight - normalized[i] * (chartHeight - 10) + 5;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i * chartHeight / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line
    final linePaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = primary;
    final haloPaint = Paint()..color = primary.withOpacity(0.08);
    for (final point in points) {
      canvas.drawCircle(point, 8, haloPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyLinePainter old) =>
      old.primary != primary ||
      old.gridColor != gridColor ||
      old.values != values;
}

// ── Achievements Grid ─────────────────────────────────────────────────────────

class _AchievementsGrid extends StatelessWidget {
  final Color primary;
  final List<Achievement> achievements;

  const _AchievementsGrid({required this.primary, required this.achievements});

  // Maps the backend achievement ids (see backend/app/api/quiz.py) to icons.
  // Kept on the frontend so the backend response stays presentation-agnostic.
  static IconData _iconFor(String id) {
    switch (id) {
      case 'first_steps':
        return Icons.emoji_events_rounded;
      case 'seven_day_streak':
        return Icons.local_fire_department_rounded;
      case 'speed_demon':
        return Icons.bolt_rounded;
      case 'perfect_ten':
        return Icons.star_rounded;
      case 'topic_master':
        return Icons.school_rounded;
      case 'dedicated_learner':
        return Icons.psychology_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: achievements
          .map((a) => _AchievementTile(
                data: _AchievementData(
                  icon: _iconFor(a.id),
                  label: a.label,
                  desc: a.description,
                  earned: a.earned,
                ),
                primary: primary,
              ))
          .toList(),
    );
  }
}

class _AchievementData {
  final IconData icon;
  final String label;
  final String desc;
  final bool earned;
  const _AchievementData({
    required this.icon,
    required this.label,
    required this.desc,
    required this.earned,
  });
}

class _AchievementTile extends StatelessWidget {
  final _AchievementData data;
  final Color primary;

  const _AchievementTile({
    required this.data,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(data.label,
              style: TextStyle(
                  color: colors.ink, fontWeight: FontWeight.w700, fontSize: 16)),
          content:
              Text(data.desc, style: TextStyle(color: colors.muted, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK',
                  style:
                      TextStyle(color: primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      child: GlassCard(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.earned
                    ? primary.withOpacity(0.08)
                    : colors.glassChipFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: data.earned ? primary : colors.subtleMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                data.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: data.earned ? colors.ink : colors.subtleMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!data.earned) ...[
              const SizedBox(height: 4),
              Icon(Icons.lock_rounded, size: 11, color: colors.subtleMuted),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.colorsOf(context).muted,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
