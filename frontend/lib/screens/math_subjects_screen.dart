import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_preferences.dart';
import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/tap_scale.dart';

// ── Design tokens (mirrors HomeScreen exactly) ────────────────────────────────
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

class MathSubjectsScreen extends StatelessWidget {
  const MathSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final primary = palette.primary;
        final subjects = LocalContentService().getSubjects();

        return Scaffold(
          extendBody: true,
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: _surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            automaticallyImplyLeading: false,
            centerTitle: false,
            toolbarHeight: 58,
            titleSpacing: 20,
            title: const Text(
              'Lessons',
              style: TextStyle(
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
                          style: const TextStyle(
                            color: _muted,
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
                    child: _SubjectCard(
                      subject: subject,
                      primary: primary,
                      onTap: () => context.push(
                        RouteNames.lessons,
                        extra: {'subjectId': subject.id},
                      ),
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
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (subject.progress as num).toDouble();

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
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subject.gradeLevel,
                    style: const TextStyle(color: _muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: _border,
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
                    '${subject.progress}%',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _muted,
                  size: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}