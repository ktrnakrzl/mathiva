import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/data/models/subject_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/difficulty_badge.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

final topicsProvider = FutureProvider.family<List<Topic>, String>((ref, subjectId) {
  return ref.read(subjectRepositoryProvider).getTopics(subjectId);
});

class TopicListScreen extends ConsumerWidget {
  final String subjectId;
  const TopicListScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      body: topics.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final topic = items[index];
            return Card(
              child: ListTile(
                title: Text(topic.name),
                subtitle: Wrap(spacing: 6, children: topic.difficulty_available.map((value) => DifficultyBadge(difficulty: value)).toList()),
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
