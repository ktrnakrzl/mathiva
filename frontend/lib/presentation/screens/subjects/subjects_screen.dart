import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/presentation/state/subject_notifier.dart';
import 'package:mathiva/presentation/widgets/common_widgets.dart';
import '../../../widgets/mathiva_app_bar.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: MathivaAppBar(
        title: 'Choose a Subject',
        subtitle: 'Pick a topic to explore',
        icon: Icons.school_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: subjectsAsync.when(
        loading: () => const LoadingSpinner(),
        error: (error, st) => ErrorWidget(
          message: 'Failed to load subjects: $error',
          onRetry: () {
            ref.refresh(subjectsProvider);
          },
        ),
        data: (subjects) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(subjectsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return GestureDetector(
                  onTap: () => context.push('/subject/${subject.subjectId}'),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subject.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${subject.topics.length} topics',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${subject.masteredTopics} mastered',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
