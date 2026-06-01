import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/data/models/subject_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

final subjectsProvider = FutureProvider<List<Subject>>((ref) {
  return ref.read(subjectRepositoryProvider).getSubjects();
});

class SubjectSelectScreen extends ConsumerWidget {
  const SubjectSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Subject')),
      body: subjects.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final subject = items[index];
            return Card(
              child: ListTile(
                title: Text(subject.name),
                subtitle: Text(subject.grade_level),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/subjects/${subject.subject_id}/topics'),
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
