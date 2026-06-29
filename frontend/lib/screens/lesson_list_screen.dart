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

class LessonListScreen extends StatelessWidget {
  final String subjectId;
  const LessonListScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);
    final subject = LocalContentService().getSubject(subjectId);
    final lessons = subject.topics
        .expand(
            (topic) => topic.lessons.map((lesson) => MapEntry(topic, lesson)))
        .toList();

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
              scrolledUnderElevation: 1,
              shadowColor: primary.withOpacity(0.12),
              automaticallyImplyLeading: false,
              centerTitle: false,
              toolbarHeight: 58,
              titleSpacing: 20,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: colors.ink, size: 22),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
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
            itemCount: lessons.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Pick a lesson to continue',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              final topic = lessons[index - 1].key;
              final lesson = lessons[index - 1].value;
              final isLocked = lesson.locked;

              return FadeSlideIn(
                delay: Duration(milliseconds: 60 * index),
                child: _LessonCard(
                  topic: topic.title,
                  lesson: lesson,
                  primary: primary,
                  onTap: isLocked
                      ? null
                      : () => context.push(
                            RouteNames.lessonDetail,
                            extra: {
                              'subjectId': subject.id,
                              'topicId': topic.id,
                              'lessonId': lesson.id,
                            },
                          ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Lesson Card ───────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final dynamic topic;
  final dynamic lesson;
  final Color primary;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.topic,
    required this.lesson,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = onTap == null;
    final colors = AppTheme.colorsOf(context);

    // GlassCard already handles the tap/no-tap distinction (it only wraps
    // in TapScale when onTap is non-null), so locked cards just need the
    // dimming on top.
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.menu_book_rounded,
                color: primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),

            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$topic · ${lesson.duration}',
                    style: TextStyle(color: colors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Icon(
              Icons.arrow_forward_rounded,
              color: isLocked ? colors.muted : primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
