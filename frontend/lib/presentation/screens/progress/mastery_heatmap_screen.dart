import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/data/models/progress_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

final masteryProvider = FutureProvider<List<TopicMastery>>((ref) {
  return ref.read(progressRepositoryProvider).getMastery(AppStrings.studentId);
});

class MasteryHeatmapScreen extends ConsumerWidget {
  const MasteryHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(masteryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mastery Heatmap')),
      body: mastery.when(
        data: (items) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.3, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(item.topic_name, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('${item.mastery_level}%', style: Theme.of(context).textTheme.headlineSmall),
                  Text('Last: ${item.last_practiced}', style: Theme.of(context).textTheme.bodySmall),
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
