import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/core/utils/math_renderer.dart';
import 'package:mathiva/data/models/review_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);

final reviewQueueProvider = FutureProvider<List<ReviewQuestion>>((ref) {
  return ref
      .read(reviewRepositoryProvider)
      .getReviewQueue(AppStrings.studentId);
});

class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reviewQueueProvider);
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Review Queue',
        subtitle: 'Your spaced repetition queue',
        icon: Icons.replay_rounded,
        showBack: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: queue.when(
            data: (items) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 28),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const SectionHeader(
                    title: 'Review Queue',
                    subtitle: 'Items due for spaced review',
                  );
                }
                final item = items[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 60 * index),
                    child: _SoftCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  palette.primary.withOpacity(.14),
                                  palette.secondary.withOpacity(.14)
                                ]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Due: ${item.due_date}',
                                  style: TextStyle(
                                      color: palette.primary,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(height: 14),
                            MathRenderer(
                                text: item.question_text,
                                textStyle: const TextStyle(
                                    color: _ink, fontWeight: FontWeight.w800),
                                mathFontSize: 16),
                            const SizedBox(height: 12),
                            ...item.choices.map((choice) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('• $choice',
                                    style: const TextStyle(color: _muted)))),
                          ]),
                    ),
                  ),
                );
              },
            ),
            loading: () => const LoadingOverlay(),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC).withOpacity(.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))
          ],
        ),
        child: child,
      );
}
