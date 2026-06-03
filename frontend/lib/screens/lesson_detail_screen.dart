import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/progress_line.dart';
import '../widgets/section_card.dart';

class LessonDetailScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;

  const LessonDetailScreen({super.key, required this.subjectId, required this.topicId, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final service = LocalContentService();
    final lesson = service.getLesson(subjectId, topicId, lessonId);
    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(title: lesson.title, subtitle: '${lesson.duration} lesson'),
            const SizedBox(height: 18),
            const Text('Lesson Concepts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('This lesson is divided into key concepts.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            ...lesson.concepts.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    onTap: () => Navigator.pushNamed(context, RouteNames.concept, arguments: {
                      'subjectId': subjectId,
                      'topicId': topicId,
                      'lessonId': lessonId,
                      'conceptId': entry.value.id,
                    }),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: AppPreferences.palette.value.secondary.withOpacity( .14), child: Text('${entry.key + 1}', style: TextStyle(color: AppPreferences.palette.value.secondary, fontWeight: FontWeight.w900))),
                        const SizedBox(width: 14),
                        Expanded(child: Text(entry.value.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  ProgressLine(percent: 28),
                  SizedBox(height: 8),
                  Text('28% Completed', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Continue Reading',
              onPressed: () {
                final firstConcept = lesson.concepts.first;
                Navigator.pushNamed(context, RouteNames.concept, arguments: {'subjectId': subjectId, 'topicId': topicId, 'lessonId': lessonId, 'conceptId': firstConcept.id});
              },
            ),
          ],
        ),
      ),
    );
  }
}
