import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/core/utils/math_renderer.dart';
import 'package:mathiva/presentation/notifiers/tutor_notifier.dart';
import 'package:mathiva/presentation/widgets/difficulty_badge.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/step_revealer.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _questionController = TextEditingController(text: 'Is f(x)=2x+1 a function?');

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutorState = ref.watch(tutorNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('RAG Tutor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _questionController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Math question'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.read(tutorNotifierProvider.notifier).askQuestion(_questionController.text, 'gen_math', 'gen_math_functions'),
            child: const Text('Ask Tutor'),
          ),
          const SizedBox(height: 20),
          tutorState.when(
            data: (response) => response == null
                ? const Text(AppStrings.askPrompt)
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DifficultyBadge(difficulty: response.difficulty),
                          const SizedBox(height: 12),
                          MathRenderer(text: response.answer),
                          const SizedBox(height: 12),
                          StepRevealer(steps: response.steps),
                          const SizedBox(height: 12),
                          Text('Source: ${response.source_chunks.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
            loading: () => const LoadingOverlay(),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }
}
