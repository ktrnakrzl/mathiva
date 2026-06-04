import 'dart:async';

import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../models/mathiva_models.dart';
import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/progress_line.dart';
import '../widgets/section_card.dart';

class PracticeScreen extends StatefulWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;
  final String difficulty;

  const PracticeScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
    required this.conceptId,
    required this.difficulty,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  String? _selectedAnswer;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String> _choicesFor(PracticeProblem problem) {
    if (problem.choices.isNotEmpty) return problem.choices;
    final answer = problem.answer;
    if (answer.contains('-1') && answer.contains('-3/2')) {
      return [answer, 'x = 1 and x = 3/2', 'x = -2 and x = -3', 'x = 0 and x = -5/2'];
    }
    if (answer == '9' || answer == 'f(4) = 9') return [answer, '7', '8', '10'];
    if (answer == 'x + 1') return [answer, 'x - 1', 'x^2 + 1', '1'];
    if (answer == '3') return [answer, '2', '4', '5'];
    if (answer == '6') return [answer, '5', '7', '8'];
    if (answer == '1/2') return [answer, '1/4', '1/3', '2'];
    if (answer == '3/5') return [answer, '5/3', '6/10 only', '4/5'];
    if (answer == '4') return [answer, '2', '8', '16'];
    return [answer, 'Not enough information', '0', '1'];
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void _submit() {
    if (_submitted || !mounted) return;
    _submitted = true;
    _timer?.cancel();
    final concept = LocalContentService().getConcept(widget.subjectId, widget.topicId, widget.lessonId, widget.conceptId);
    final selected = _selectedAnswer;
    Navigator.pushReplacementNamed(context, RouteNames.result, arguments: {
      'subjectId': widget.subjectId,
      'topicId': widget.topicId,
      'lessonId': widget.lessonId,
      'conceptId': widget.conceptId,
      'difficulty': widget.difficulty,
      'selectedAnswer': selected,
      'elapsedSeconds': _elapsedSeconds,
      'isCorrect': selected == concept.problem.answer,
    });
  }

  @override
  Widget build(BuildContext context) {
    final concept = LocalContentService().getConcept(widget.subjectId, widget.topicId, widget.lessonId, widget.conceptId);
    final problem = concept.problem;
    final choices = _choicesFor(problem);
    return Scaffold(
      body: GradientBackground(
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const AppHeader(title: 'Practice', subtitle: '1/1 multiple-choice problem'),
            const SizedBox(height: 12),
            const ProgressLine(percent: 100),
            const SizedBox(height: 16),
            Row(
              children: ['Easy', 'Medium', 'Hard']
                  .map((level) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: level == widget.difficulty ? Theme.of(context).colorScheme.primary : Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Center(child: Text(level, style: TextStyle(color: level == widget.difficulty ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900))),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Problem', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(problem.question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                        const SizedBox(height: 20),
                        const Text('Choose the correct answer', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        ...choices.map((choice) {
                          final selected = choice == _selectedAnswer;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.12) : AppPreferences.palette.value.primary.withOpacity(.04),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => setState(() => _selectedAnswer = choice),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? Theme.of(context).colorScheme.primary : AppColors.muted),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(choice, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => _selectedAnswer = null), child: const Text('Clear'))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedAnswer == null ? null : () => _submit(),
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(.10),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
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
