import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../utils/duration_format.dart';
import '../utils/progress_calc.dart';
import '../utils/route_names.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../theme/app_theme.dart';

class SubjectProgressScreen extends StatefulWidget {
  final String subjectId;
  const SubjectProgressScreen({super.key, required this.subjectId});

  @override
  State<SubjectProgressScreen> createState() => _SubjectProgressScreenState();
}

class _SubjectProgressScreenState extends State<SubjectProgressScreen> {
  @override
  void initState() {
    super.initState();
    ProgressStore.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);
    final subject = LocalContentService().getSubject(widget.subjectId);

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
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/progress'),
              ),
              title: Text(
                subject.title,
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
              final overallPct =
                  (subjectProgress(subject, byConcept) * 100).round();

              // Per-subject activity stats (study time + accuracy). Absent
              // until the learner attempts something in this subject → real
              // zero-state, not a fabricated number.
              SubjectStat? subjectStat;
              if (progress != null) {
                for (final s in progress.bySubject) {
                  if (s.subjectId == subject.id) {
                    subjectStat = s;
                    break;
                  }
                }
              }
              final studyTime = subjectStat != null
                  ? formatElapsed(subjectStat.totalElapsedSeconds)
                  : '0s';
              final accuracy = subjectStat != null
                  ? '${subjectStat.accuracy.round()}%'
                  : '0%';
              final lessons = lessonsCompletedFraction(subject, byConcept);

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                children: [
                  // ── Overall progress card ──────────────────────────────────
                  FadeSlideIn(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Overall Progress',
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
                                  '$overallPct%',
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
                              value: (overallPct / 100).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: colors.glassBorderSoft,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primary),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(
                              color: colors.glassBorderSoft,
                              height: 1,
                              thickness: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: _SmallStat(
                                      label: 'Study Time', value: studyTime)),
                              Expanded(
                                  child: _SmallStat(
                                      label: 'Accuracy', value: accuracy)),
                              Expanded(
                                  child: _SmallStat(
                                      label: 'Lessons', value: lessons)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Topic Progress label ───────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Topic Progress',
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  // ── Topic rows ─────────────────────────────────────────────
                  ...subject.topics.asMap().entries.map((entry) {
                    final i = entry.key;
                    final topic = entry.value;
                    final topicPct =
                        (topicProgress(topic, byConcept) * 100).round();
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 80 + 50 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TopicCard(
                          topic: topic,
                          primary: primary,
                          progressPercent: topicPct,
                          onTap: () => context.push(
                            RouteNames.topicAnalytics,
                            extra: {
                              'subjectId': subject.id,
                              'topicId': topic.id,
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Topic Card ────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final dynamic topic;
  final Color primary;
  final int progressPercent; // real mastery %, computed from attempt history
  final VoidCallback onTap;

  const _TopicCard({
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
      padding: const EdgeInsets.all(18),
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

// ── Small Stat ────────────────────────────────────────────────────────────────

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;

  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(color: colors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
