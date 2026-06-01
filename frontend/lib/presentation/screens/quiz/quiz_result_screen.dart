import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/presentation/notifiers/quiz_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: state.when(
        data: (quizState) {
          final result = quizState.result;
          if (result == null) return const Center(child: Text('Finish a quiz first.'));
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${result.score}/${result.total}', style: Theme.of(context).textTheme.headlineMedium),
                    Text(result.passed ? 'Passed' : 'Needs more practice'),
                    Text('Points earned: ${result.points_earned}'),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
