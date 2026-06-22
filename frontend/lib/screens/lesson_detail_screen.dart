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
    final lesson = LocalContentService().getLesson(subjectId, topicId, lessonId);

    return Scaffold(
      extendBody: true,
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 58,
        titleSpacing: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          lesson.title,
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
          child: Container(height: 1, color: const Color(0xFFF1F0F8)),
        ),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              // ── Overview card ──────────────────────────────────────────────
              FadeSlideIn(
                child: _WhiteCard(
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
                                const Text(
                                  'Lesson Overview',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${lesson.concepts.length} concepts · ${lesson.duration}',
                                  style: const TextStyle(
                                      color: _muted, fontSize: 12.5),
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
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Concepts',
                    style: TextStyle(
                      color: _muted,
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
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, color: primary, size: 16),
          ],
        ),
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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
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