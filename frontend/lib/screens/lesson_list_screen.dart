import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/tap_scale.dart';

// ── Design tokens (mirrors HomeScreen exactly) ────────────────────────────────
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

// Shared app-chrome surface — matches HomeScreen's AppBar treatment so the
// header reads as the same layer of chrome across screens.
const _chromeSurface = Color(0xFFF6F5FB);
const _chromeBorder = Color(0xFFEAE8F5);

class LessonListScreen extends StatelessWidget {
  final String subjectId;
  const LessonListScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final subject = LocalContentService().getSubject(subjectId);
    final lessons = subject.topics
        .expand(
            (topic) => topic.lessons.map((lesson) => MapEntry(topic, lesson)))
        .toList();

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          subject.title,
          style: const TextStyle(
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
                    child: const Text(
                      'Pick a lesson to continue',
                      style: TextStyle(
                        color: _muted,
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

    final card = Opacity(
      opacity: isLocked ? 0.5 : 1.0,
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
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$topic · ${lesson.duration}',
                    style: const TextStyle(color: _muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Icon(
              Icons.arrow_forward_rounded,
              color: isLocked ? _muted : primary,
              size: 16,
            ),
          ],
        ),
      ),
    );

    if (isLocked) return card;
    return TapScale(onTap: onTap, child: card);
  }
}
