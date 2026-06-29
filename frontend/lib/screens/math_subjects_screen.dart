import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../utils/progress_calc.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../theme/app_theme.dart';

class MathSubjectsScreen extends StatefulWidget {
  const MathSubjectsScreen({super.key});

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

        return Scaffold(
          extendBody: true,
          backgroundColor: colors.pageBg,
          // Frosted-glass header, matching HomeScreen's chrome treatment.
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
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  toolbarHeight: 58,
                  titleSpacing: 20,
                  title: Text(
                    'Lessons',
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
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                itemCount: subjects.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  // Header row
                  if (index == 0) {
                    return FadeSlideIn(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Choose a subject to continue',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
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
              ),
            ),
          ),
          bottomNavigationBar:
              const MathivaBottomNav(selected: MathivaTab.lessons),
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
