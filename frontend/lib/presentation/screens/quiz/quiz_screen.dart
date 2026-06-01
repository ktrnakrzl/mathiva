import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/utils/math_renderer.dart';
import 'package:mathiva/presentation/notifiers/quiz_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(quizNotifierProvider.notifier).startQuiz('gen_math', 'gen_math_functions', 'Easy'));
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: quizState.when(
        data: (state) {
          final quiz = state.quiz;
          if (quiz == null) return const Center(child: Text('No quiz loaded.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quiz.questions.length,
            itemBuilder: (context, index) {
              final question = quiz.questions[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MathRenderer(text: question.question_text),
                      const SizedBox(height: 12),
                      ...question.choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            onPressed: () => ref.read(quizNotifierProvider.notifier).submitAnswer(quiz.quiz_id, question.question_id, choice),
                            child: Text(choice),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingOverlay(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(quizNotifierProvider.notifier).finishQuiz('quiz_001'),
        label: const Text('Finish'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
