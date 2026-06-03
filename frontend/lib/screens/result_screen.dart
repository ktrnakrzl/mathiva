import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_card.dart';

class ResultScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;
  final String difficulty;
  final String? selectedAnswer;
  final int? elapsedSeconds;
  final bool? isCorrect;

  const ResultScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
    required this.conceptId,
    required this.difficulty,
    this.selectedAnswer,
    this.elapsedSeconds,
    this.isCorrect,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final concept = LocalContentService().getConcept(subjectId, topicId, lessonId, conceptId);
    final problem = concept.problem;
    final correct = isCorrect ?? true;
    final timeText = _formatTime(elapsedSeconds ?? 0);

    return Scaffold(
      body: GradientBackground(
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
            const SizedBox(height: 10),
            Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(color: (correct ? AppPreferences.palette.value.primary : const Color(0xFFFF6B6B)).withOpacity(.15), shape: BoxShape.circle),
              child: Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: correct ? AppPreferences.palette.value.primary : const Color(0xFFFF6B6B), size: 64),
            ),
            const SizedBox(height: 16),
            Text(correct ? 'CORRECT!' : 'REVIEW NEEDED', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text('Time used: $timeText', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Answer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(selectedAnswer ?? 'No answer selected', style: TextStyle(fontSize: 18, color: correct ? AppPreferences.palette.value.primary : const Color(0xFFFF6B6B), fontWeight: FontWeight.w900)),
                        const SizedBox(height: 18),
                        const Text('Correct Answer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(problem.answer, style: TextStyle(fontSize: 20, color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 18),
                        const Text('Explanation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 8),
                        ...problem.steps.asMap().entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(radius: 13, backgroundColor: AppPreferences.palette.value.primary.withOpacity(.12), child: Text('${entry.key + 1}', style: TextStyle(fontSize: 12, color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900))),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(entry.value, style: const TextStyle(height: 1.4))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: 'Next Concept',
                    onPressed: () => Navigator.pushNamed(context, RouteNames.conceptProgress, arguments: {'subjectId': subjectId, 'topicId': topicId, 'lessonId': lessonId}),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
