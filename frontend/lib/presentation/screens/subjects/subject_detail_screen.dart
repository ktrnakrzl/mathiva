import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva_flutter/presentation/state/subject_notifier.dart';
import 'package:mathiva_flutter/presentation/widgets/common_widgets.dart';
import '../../../widgets/mathiva_app_bar.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectDetailScreen({
    Key? key,
    required this.subjectId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(subjectByIdProvider(subjectId));

    return Scaffold(
      appBar: MathivaAppBar(
        title: 'Subject Detail',
        subtitle: 'Explore topics',
        icon: Icons.explore_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: subjectAsync.when(
        loading: () => const LoadingSpinner(),
        error: (error, st) => ErrorWidget(
          message: 'Failed to load subject: $error',
          onRetry: () {
            ref.refresh(subjectByIdProvider(subjectId));
          },
        ),
        data: (subject) {
          return Column(
            children: [
              // Subject Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subject.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // Topics List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(subjectByIdProvider(subjectId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: subject.topics.length,
                    itemBuilder: (context, index) {
                      final topic = subject.topics[index];
                      return TopicCard(
                        title: topic.name,
                        masteryPercentage: topic.masteryPercentage,
                        onTap: () {
                          _showTopicOptions(context, topic.topicId);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTopicOptions(BuildContext context, String topicId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Take Quiz'),
              onTap: () {
                Navigator.pop(context);
                context.push('/quiz/$topicId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Ask Tutor'),
              onTap: () {
                Navigator.pop(context);
                context.push('/tutor/topic/$topicId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay_outlined),
              title: const Text('Review Questions'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to review screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
