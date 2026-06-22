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

class ConceptReadingScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;

  const ConceptReadingScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
    required this.conceptId,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final concept =
        LocalContentService().getConcept(subjectId, topicId, lessonId, conceptId);

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
              context.canPop() ? context.pop() : context.go('/lesson-detail'),
        ),
        title: Text(
          concept.title,
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
              // ── Concept label pill ─────────────────────────────────────────
              FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: primary.withOpacity(0.15)),
                        ),
                        child: Text(
                          'Concept Reading',
                          style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Definition card ────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Definition', primary: primary),
                      const SizedBox(height: 10),
                      Text(
                        concept.definition,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14.5,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Formula card ───────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Formula', primary: primary),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: primary.withOpacity(0.12)),
                        ),
                        child: Text(
                          concept.formula,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Example card ───────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Example', primary: primary),
                      const SizedBox(height: 10),
                      Text(
                        concept.example,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14.5,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── CTA ────────────────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: _PrimaryButton(
                  label: 'Practice this Concept',
                  primary: primary,
                  onPressed: () => _showDifficulty(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficulty(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose Difficulty',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _muted, size: 20),
                  onPressed: () => sheetContext.pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final difficulty in ['Easy', 'Medium', 'Hard'])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DifficultyTile(
                  label: difficulty,
                  primary: primary,
                  onTap: () {
                    sheetContext.pop();
                    context.push(
                      RouteNames.practice,
                      extra: {
                        'subjectId': subjectId,
                        'topicId': topicId,
                        'lessonId': lessonId,
                        'conceptId': conceptId,
                        'difficulty': difficulty,
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color primary;
  const _SectionLabel({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: primary,
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

// ── Difficulty Tile ───────────────────────────────────────────────────────────

class _DifficultyTile extends StatelessWidget {
  final String label;
  final Color primary;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: primary, size: 16),
          ],
        ),
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
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}