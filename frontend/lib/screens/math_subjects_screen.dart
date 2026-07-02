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

class MathSubjectsScreen extends StatefulWidget {
  /// When true, renders only the scrollable subject list (no Scaffold, top bar
  /// or bottom nav) so it can be embedded as a segment inside the merged
  /// "Learn" tab. Standalone (pushed) use keeps the full shell.
  final bool embedded;
  const MathSubjectsScreen({super.key, this.embedded = false});

  @override
  State<MathSubjectsScreen> createState() => _MathSubjectsScreenState();
}

class _MathSubjectsScreenState extends State<MathSubjectsScreen> {
  @override
  void initState() {
    super.initState();
    ProgressStore.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final primary = palette.primary;
        final colors = AppTheme.colorsOf(context);
        final subjects = LocalContentService().getSubjects();
        final embedded = widget.embedded;

        final list = ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(18, embedded ? 4 : 22, 18, 112),
          itemCount: subjects.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            // Header: page title + subtitle (title lives in the body, not the
            // top bar, per the shadcn shell pattern). When embedded inside the
            // "Learn" tab the segmented control supplies the heading, so we
            // show only the subtitle here.
            if (index == 0) {
              return FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!embedded) ...[
                        Text(
                          'Lessons',
                          style: AppTheme.serif(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Choose a subject to continue',
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final subject = subjects[index - 1];

            return FadeSlideIn(
              delay: Duration(milliseconds: 60 * index),
              child: ValueListenableBuilder<UserProgress?>(
                valueListenable: ProgressStore.current,
                builder: (context, progress, _) {
                  final byConcept = progress?.conceptStats ?? const {};
                  final pct =
                      (subjectProgress(subject, byConcept) * 100).round();
                  return _SubjectCard(
                    subject: subject,
                    primary: primary,
                    progressPercent: pct,
                    onTap: () => context.push(
                      RouteNames.lessons,
                      extra: {'subjectId': subject.id},
                    ),
                  );
                },
              ),
            );
          },
        );

        // Embedded: caller (LearnScreen) owns the shell.
        if (embedded) return list;

        return Scaffold(
          extendBody: true,
          backgroundColor: colors.pageBg,
          appBar: const MathivaTopBar(),
          body: AnimatedBackground(
            vivid: true,
            child: SafeArea(top: false, child: list),
          ),
          bottomNavigationBar:
              const MathivaBottomNav(selected: MathivaTab.learn),
        );
      },
    );
  }
}

// ── Subject Card ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final dynamic subject; // matches existing data model
  final Color primary;
  final int progressPercent; // real mastery %, computed from attempt history
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
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
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(subject.subjectIcon, color: primary, size: 24),
          ),
          const SizedBox(width: 14),

          // Title + grade + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.title,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subject.gradeLevel,
                  style: TextStyle(color: colors.muted, fontSize: 12.5),
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
          ),
          const SizedBox(width: 14),

          // Progress label + chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              const SizedBox(height: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: colors.muted,
                size: 15,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
