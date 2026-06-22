import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/tap_scale.dart';

// ── Design tokens (mirrors HomeScreen exactly) ────────────────────────────────
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

// Shared app-chrome surface — matches the header treatment on HomeScreen
// (and MathivaBottomNav) so this screen's header reads as the same layer
// of app chrome, sitting just above the white content surfaces below.
const _chromeSurface = Color(0xFFF6F5FB);
const _chromeBorder = Color(0xFFEAE8F5);

class ProgressOverviewScreen extends StatefulWidget {
  final bool scrollToAchievements;
  const ProgressOverviewScreen({super.key, this.scrollToAchievements = false});

  @override
  State<ProgressOverviewScreen> createState() => _ProgressOverviewScreenState();
}

class _ProgressOverviewScreenState extends State<ProgressOverviewScreen> {
  final _scrollController = ScrollController();
  final _achievementsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
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
    final subjects = LocalContentService().getSubjects();
    final topics = subjects.expand((s) => s.topics).toList();

    return Scaffold(
      extendBody: true,
      backgroundColor: _pageBg,
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
        title: const Text(
          'Progress',
          style: TextStyle(
            color: Color(0xFF312E81),
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            height: 1,
          ),
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
          child: Container(height: 1, color: _chromeBorder),
        ),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              // ── Stat cards ─────────────────────────────────────────────────
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
                          value: '128',
                          icon: Icons.check_circle_outline_rounded,
                          primary: primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Accuracy',
                          value: '86%',
                          icon: Icons.track_changes_rounded,
                          primary: primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Streak Days',
                          value: '12',
                          icon: Icons.local_fire_department_rounded,
                          primary: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Weekly activity card ────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Weekly Activity'),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: _WeeklyLineChart(primary: primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Topic Mastery label ─────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Topic Mastery',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Topic mastery rows ──────────────────────────────────────────
              ...topics.asMap().entries.map((entry) {
                final i = entry.key;
                final topic = entry.value;
                final subjectId = subjects
                    .firstWhere((s) => s.topics.contains(topic))
                    .id;
                return FadeSlideIn(
                  delay: Duration(milliseconds: 120 + 50 * i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TopicMasteryCard(
                      topic: topic,
                      primary: primary,
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

              // ── Achievements label ──────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: Padding(
                  key: _achievementsKey,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: const Text(
                    'Achievements',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // ── Achievements grid ───────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: _AchievementsGrid(primary: primary),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          const MathivaBottomNav(selected: MathivaTab.progress),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 10.5),
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
  final VoidCallback onTap;

  const _TopicMasteryCard({
    required this.topic,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (topic.progress as num).toDouble();

    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: const TextStyle(
                      color: _ink,
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
                    '${topic.progress}%',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: _muted, size: 15),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (progress / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: _border,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Line Chart ─────────────────────────────────────────────────────────

class _WeeklyLineChart extends StatelessWidget {
  final Color primary;
  const _WeeklyLineChart({required this.primary});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WeeklyLinePainter(primary: primary),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('M', style: TextStyle(color: _muted, fontSize: 11)),
              Text('T', style: TextStyle(color: _muted, fontSize: 11)),
              Text('W', style: TextStyle(color: _muted, fontSize: 11)),
              Text('T', style: TextStyle(color: _muted, fontSize: 11)),
              Text('F', style: TextStyle(color: _muted, fontSize: 11)),
              Text('S', style: TextStyle(color: _muted, fontSize: 11)),
              Text('S', style: TextStyle(color: _muted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyLinePainter extends CustomPainter {
  final Color primary;
  const _WeeklyLinePainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.25, 0.45, 0.38, 0.65, 0.58, 0.8, 0.72];
    final chartHeight = size.height - 26;
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = i * (size.width / (values.length - 1));
      final y = chartHeight - values[i] * (chartHeight - 10) + 5;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = _border
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
      old.primary != primary;
}

// ── Achievements Grid ─────────────────────────────────────────────────────────

class _AchievementsGrid extends StatelessWidget {
  final Color primary;

  static const _achievements = [
    _AchievementData(
        icon: Icons.emoji_events_rounded,
        label: 'First Win',
        desc: 'Solved your first problem',
        earned: true),
    _AchievementData(
        icon: Icons.local_fire_department_rounded,
        label: '7-Day Streak',
        desc: 'Practiced 7 days in a row',
        earned: true),
    _AchievementData(
        icon: Icons.bolt_rounded,
        label: 'Speed Demon',
        desc: 'Solved a problem in under 10s',
        earned: true),
    _AchievementData(
        icon: Icons.star_rounded,
        label: 'Perfect Score',
        desc: 'Got 100% on a quiz',
        earned: false),
    _AchievementData(
        icon: Icons.school_rounded,
        label: 'Topic Master',
        desc: 'Mastered an entire topic',
        earned: false),
    _AchievementData(
        icon: Icons.psychology_rounded,
        label: 'Big Brain',
        desc: 'Solved 50 hard problems',
        earned: false),
  ];

  const _AchievementsGrid({required this.primary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: _achievements
          .map((a) => _AchievementTile(data: a, primary: primary))
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
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(data.label,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 16)),
          content: Text(data.desc,
              style: const TextStyle(color: _muted, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK',
                  style: TextStyle(
                      color: primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.earned
                    ? primary.withOpacity(0.08)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: data.earned ? primary : const Color(0xFFCBD5E1),
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
                  color: data.earned ? _ink : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!data.earned) ...[
              const SizedBox(height: 4),
              const Icon(Icons.lock_rounded,
                  size: 11, color: Color(0xFFCBD5E1)),
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
      style: const TextStyle(
        color: _muted,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── White Card ────────────────────────────────────────────────────────────────

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}