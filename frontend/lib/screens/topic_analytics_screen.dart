import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../utils/progress_calc.dart';
import '../utils/route_names.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../theme/app_theme.dart';

class TopicAnalyticsScreen extends StatefulWidget {
  final String subjectId;
  final String topicId;

  const TopicAnalyticsScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
  });

  @override
  State<TopicAnalyticsScreen> createState() => _TopicAnalyticsScreenState();
}

class _TopicAnalyticsScreenState extends State<TopicAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    ProgressStore.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final secondary = AppPreferences.palette.value.secondary;
    final colors = AppTheme.colorsOf(context);
    final topic = LocalContentService().getTopic(widget.subjectId, widget.topicId);

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.pageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: colors.glassFillStart,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              centerTitle: false,
              toolbarHeight: 58,
              titleSpacing: 4,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: colors.ink, size: 22),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/subject-progress'),
              ),
              title: Text(
                topic.title,
                style: TextStyle(
                  color: colors.titleColor,
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
                child: Container(height: 1, color: colors.glassBorder),
              ),
            ),
          ),
        ),
      ),
      body: AnimatedBackground(
        vivid: true,
        child: SafeArea(
          top: false,
          child: ValueListenableBuilder<UserProgress?>(
            valueListenable: ProgressStore.current,
            builder: (context, progress, _) {
              final byConcept = progress?.conceptStats ?? const {};
              final masteryPct = (topicProgress(topic, byConcept) * 100).round();

              // Topic-level activity stat (correct/incorrect ratio). Absent
              // until the learner attempts a problem in this topic.
              TopicStat? topicStat;
              if (progress != null) {
                for (final t in progress.byTopic) {
                  if (t.topicId == topic.id) {
                    topicStat = t;
                    break;
                  }
                }
              }
              final hasAttempts = topicStat != null && topicStat.attempts > 0;

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                children: [
                  // ── Performance overview card (curriculum mastery) ─────────
                  FadeSlideIn(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Performance Overview',
                                  style: TextStyle(
                                    color: colors.ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: primary.withOpacity(0.12)),
                                ),
                                child: Text(
                                  '$masteryPct%',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: (masteryPct / 100).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: colors.glassBorderSoft,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Everything below is *activity*-derived. With no attempts
                  // yet, an all-zero ring/breakdown would read as failure on
                  // untried content, so we show a friendly empty-state instead.
                  if (!hasAttempts)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: GlassCard(
                        child: Column(
                          children: [
                            Icon(Icons.insights_rounded,
                                color: colors.muted, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'No attempts yet',
                              style: TextStyle(
                                color: colors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Practice a problem in this topic to see your '
                              'score breakdown and difficulty stats here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colors.muted, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildActivitySections(
                      context: context,
                      colors: colors,
                      primary: primary,
                      secondary: secondary,
                      topic: topic,
                      topicStat: topicStat,
                      progress: progress!,
                      byConcept: byConcept,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Score-breakdown ring, correct/incorrect legend, difficulty tiles and the
  /// "Concepts to Review" list — all only rendered once the topic has at least
  /// one recorded attempt.
  List<Widget> _buildActivitySections({
    required BuildContext context,
    required dynamic colors,
    required Color primary,
    required Color secondary,
    required dynamic topic,
    required TopicStat topicStat,
    required UserProgress progress,
    required Map<String, ConceptStat> byConcept,
  }) {
    final accuracyPct = topicStat.accuracy.round();
    final incorrect = topicStat.attempts - topicStat.correct;
    final incorrectPct = 100 - accuracyPct;

    // Difficulty breakdown for this topic, looked up by name.
    String difficultyValue(String label) {
      for (final d in progress.byTopicDifficulty) {
        if (d.topicId == topic.id && d.difficulty == label && d.attempts > 0) {
          return '${d.accuracy.round()}%';
        }
      }
      return '—'; // no data ≠ 0% accuracy
    }

    // Lowest-accuracy attempted concepts within this topic (up to 3).
    final reviewConcepts = <_ReviewConcept>[];
    for (final lesson in topic.lessons) {
      for (final concept in lesson.concepts) {
        final stat = byConcept[concept.id];
        if (stat != null && stat.attempts > 0) {
          reviewConcepts
              .add(_ReviewConcept(concept.title, stat.accuracy.round()));
        }
      }
    }
    reviewConcepts.sort((a, b) => a.percent.compareTo(b.percent));
    final toReview = reviewConcepts.take(3).toList();

    return [
      // ── Score breakdown card ───────────────────────────────────────────
      FadeSlideIn(
        delay: const Duration(milliseconds: 60),
        child: GlassCard(
          child: Column(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: (accuracyPct / 100).clamp(0.0, 1.0),
                        strokeWidth: 14,
                        backgroundColor: colors.glassBorderSoft,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    Text(
                      '$accuracyPct%',
                      style: TextStyle(
                        color: primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: colors.glassBorderSoft, height: 1, thickness: 1),
              const SizedBox(height: 16),
              _Legend(
                  label: 'Correct',
                  value: '$accuracyPct% / ${topicStat.correct}',
                  color: primary),
              _Legend(
                  label: 'Incorrect',
                  value: '$incorrectPct% / $incorrect',
                  color: secondary),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),

      // ── Difficulty breakdown ───────────────────────────────────────────
      FadeSlideIn(
        delay: const Duration(milliseconds: 100),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Difficulty Breakdown',
            style: TextStyle(
              color: colors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
      FadeSlideIn(
        delay: const Duration(milliseconds: 120),
        child: Row(
          children: [
            Expanded(
                child: _DifficultyCard(
                    label: 'Easy',
                    value: difficultyValue('Easy'),
                    primary: primary)),
            const SizedBox(width: 10),
            Expanded(
                child: _DifficultyCard(
                    label: 'Medium',
                    value: difficultyValue('Medium'),
                    primary: primary)),
            const SizedBox(width: 10),
            Expanded(
                child: _DifficultyCard(
                    label: 'Hard',
                    value: difficultyValue('Hard'),
                    primary: primary)),
          ],
        ),
      ),

      // ── Concepts to review ─────────────────────────────────────────────
      if (toReview.isNotEmpty) ...[
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Concepts to Review',
              style: TextStyle(
                color: colors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: GlassCard(
            child: Column(
              children: [
                for (var i = 0; i < toReview.length; i++)
                  _WeakTopicRow(
                    label: toReview[i].title,
                    percent: toReview[i].percent,
                    primary: primary,
                    showDivider: i != toReview.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    ];
  }
}

class _ReviewConcept {
  final String title;
  final int percent;
  const _ReviewConcept(this.title, this.percent);
}

// ── Legend Row ────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Legend({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Difficulty Card ───────────────────────────────────────────────────────────

class _DifficultyCard extends StatelessWidget {
  final String label;
  final String value;
  final Color primary;

  const _DifficultyCard({
    required this.label,
    required this.value,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weak Topic / Concept-to-review Row ──────────────────────────────────────────

class _WeakTopicRow extends StatelessWidget {
  final String label;
  final int percent;
  final Color primary;
  final bool showDivider;

  const _WeakTopicRow({
    required this.label,
    required this.percent,
    required this.primary,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withOpacity(0.12)),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: colors.glassBorderSoft, height: 1, thickness: 1),
      ],
    );
  }
}
