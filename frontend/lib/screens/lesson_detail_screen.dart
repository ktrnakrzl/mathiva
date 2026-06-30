import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../theme/app_theme.dart';

class LessonDetailScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);
    final lesson =
        LocalContentService().getLesson(subjectId, topicId, lessonId);

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.pageBg,
      // Frosted-glass header, matching HomeScreen's chrome treatment.
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
              centerTitle: false,
              toolbarHeight: 58,
              titleSpacing: 4,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: colors.ink, size: 22),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              title: Text(
                lesson.title,
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
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              // ── Overview card ──────────────────────────────────────────────
              FadeSlideIn(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(Icons.auto_awesome_rounded,
                                color: primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lesson Overview',
                                  style: TextStyle(
                                    color: colors.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${lesson.concepts.length} concepts · ${lesson.duration}',
                                  style: TextStyle(
                                      color: colors.muted, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _PrimaryButton(
                        label: 'Start Lesson',
                        primary: primary,
                        onPressed: () => context.push(
                          RouteNames.concept,
                          extra: {
                            'subjectId': subjectId,
                            'topicId': topicId,
                            'lessonId': lessonId,
                            'conceptId': lesson.concepts.first.id,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section label ──────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Concepts',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // ── Concept list ───────────────────────────────────────────────
              ...lesson.concepts.asMap().entries.map((entry) {
                final i = entry.key;
                final concept = entry.value;
                return FadeSlideIn(
                  delay: Duration(milliseconds: 80 + 60 * i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ConceptCard(
                      concept: concept,
                      primary: primary,
                      onTap: () => context.push(
                        RouteNames.concept,
                        extra: {
                          'subjectId': subjectId,
                          'topicId': topicId,
                          'lessonId': lessonId,
                          'conceptId': concept.id,
                        },
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Concept Card ──────────────────────────────────────────────────────────────

class _ConceptCard extends StatelessWidget {
  final dynamic concept;
  final Color primary;
  final VoidCallback onTap;

  const _ConceptCard({
    required this.concept,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.lightbulb_outline_rounded,
                color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              concept.title,
              style: TextStyle(
                color: AppTheme.colorsOf(context).ink,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_forward_rounded, color: primary, size: 16),
        ],
      ),
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color primary;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1),
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
