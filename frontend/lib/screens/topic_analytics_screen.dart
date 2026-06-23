import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';

// ── Design tokens (mirrors HomeScreen exactly) ────────────────────────────────
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

class TopicAnalyticsScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;

  const TopicAnalyticsScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final secondary = AppPreferences.palette.value.secondary;
    final topic = LocalContentService().getTopic(subjectId, topicId);

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
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/subject-progress'),
        ),
        title: Text(
          topic.title,
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
              // ── Performance overview card ──────────────────────────────────
              FadeSlideIn(
                child: _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Performance Overview',
                              style: TextStyle(
                                color: _ink,
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
                              border:
                                  Border.all(color: primary.withOpacity(0.12)),
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (topic.progress / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: _border,
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Score breakdown card ───────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _WhiteCard(
                  child: Column(
                    children: [
                      // Ring
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
                                value: (topic.progress / 100).clamp(0.0, 1.0),
                                strokeWidth: 14,
                                backgroundColor: _border,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primary),
                              ),
                            ),
                            Text(
                              '${topic.progress}%',
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
                      const Divider(color: _border, height: 1, thickness: 1),
                      const SizedBox(height: 16),
                      _Legend(
                          label: 'Correct', value: '82% / 65', color: primary),
                      _Legend(
                          label: 'Incorrect',
                          value: '12% / 10',
                          color: secondary),
                      _Legend(
                          label: 'Skipped',
                          value: '6% / 5',
                          color: primary.withOpacity(0.25)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Difficulty breakdown label ─────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Difficulty Breakdown',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // ── Difficulty tiles ───────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Row(
                  children: [
                    Expanded(
                        child: _DifficultyCard(
                            label: 'Easy', value: '90%', primary: primary)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _DifficultyCard(
                            label: 'Medium', value: '75%', primary: primary)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _DifficultyCard(
                            label: 'Hard', value: '60%', primary: primary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Weak topics label ──────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Weak Topics',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // ── Weak topic rows ────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: _WhiteCard(
                  child: Column(
                    children: [
                      _WeakTopicRow(
                          label: 'Word Problems',
                          percent: 48,
                          primary: primary,
                          showDivider: true),
                      _WeakTopicRow(
                          label: 'Factoring',
                          percent: 62,
                          primary: primary,
                          showDivider: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
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
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
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

// ── Weak Topic Row ────────────────────────────────────────────────────────────

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
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
        if (showDivider) const Divider(color: _border, height: 1, thickness: 1),
      ],
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
