import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/core/utils/math_renderer.dart';
import 'package:mathiva/data/models/review_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

final reviewQueueProvider = FutureProvider<List<ReviewQuestion>>((ref) {
  return ref.read(reviewRepositoryProvider).getReviewQueue(AppStrings.studentId);
});

class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reviewQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Queue')),
      body: queue.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  MathRenderer(text: item.question_text),
                  const SizedBox(height: 8),
                  Text('Due: ${item.due_date}'),
                  const SizedBox(height: 8),
                  ...item.choices.map((choice) => Text('• $choice')),
                ]),
              ),
            );
          },
        ),
        loading: () => const LoadingOverlay(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
