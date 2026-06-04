import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_card.dart';

class ConceptReadingScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;

  const ConceptReadingScreen({super.key, required this.subjectId, required this.topicId, required this.lessonId, required this.conceptId});

  @override
  Widget build(BuildContext context) {
    final concept = LocalContentService().getConcept(subjectId, topicId, lessonId, conceptId);
    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(title: concept.title, subtitle: 'Concept reading card'),
            const SizedBox(height: 18),
            Text('Concept 1 out of 4', style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Definition', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(concept.definition, style: const TextStyle(height: 1.5, color: AppColors.ink)),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppPreferences.palette.value.secondary.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
                    child: Text(concept.formula, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppPreferences.palette.value.secondary)),
                  ),
                  const SizedBox(height: 18),
                  const Text('Example', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(concept.example, style: const TextStyle(height: 1.5, color: AppColors.ink)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GradientButton(
              label: 'Practice this Concept',
              icon: Icons.edit_rounded,
              onPressed: () => _showDifficulty(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficulty(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Difficulty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _DifficultyButton(label: 'Easy', color: AppPreferences.palette.value.primary, onTap: () => _goPractice(context, 'Easy')),
            _DifficultyButton(label: 'Medium', color: AppPreferences.palette.value.secondary, onTap: () => _goPractice(context, 'Medium')),
            _DifficultyButton(label: 'Hard', color: AppPreferences.palette.value.primary.withOpacity(.82), onTap: () => _goPractice(context, 'Hard')),
            Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back'))),
          ],
        ),
      ),
    );
  }

  void _goPractice(BuildContext context, String difficulty) {
    Navigator.pop(context);
    Navigator.pushNamed(context, RouteNames.practice, arguments: {
      'subjectId': subjectId,
      'topicId': topicId,
      'lessonId': lessonId,
      'conceptId': conceptId,
      'difficulty': difficulty,
    });
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity( .16), borderRadius: BorderRadius.circular(18)),
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    );
  }
}
