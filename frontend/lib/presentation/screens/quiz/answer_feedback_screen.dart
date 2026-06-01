import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/presentation/notifiers/quiz_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/step_revealer.dart';

class AnswerFeedbackScreen extends ConsumerWidget {
  const AnswerFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Answer Feedback')),
      body: state.when(
        data: (quizState) {
          final answer = quizState.lastAnswer;
          if (answer == null) return const Center(child: Text('Submit an answer first.'));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(answer.is_correct ? 'Correct!' : 'Review this item.', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Correct answer: ${answer.correct_answer}'),
                    const SizedBox(height: 12),
                    StepRevealer(steps: answer.solution_steps),
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
