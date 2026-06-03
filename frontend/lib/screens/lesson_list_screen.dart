import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/progress_line.dart';
import '../widgets/section_card.dart';

class LessonListScreen extends StatelessWidget {
  final String subjectId;
  const LessonListScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final subject = LocalContentService().getSubject(subjectId);
    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(title: subject.title, subtitle: '${subject.gradeLevel} - Lessons and topics'),
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${subject.progress}% completed', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ProgressLine(percent: subject.progress),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Topics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 12),
            ...subject.topics.map((topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(topic.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                            Text('${topic.progress}%', style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ProgressLine(percent: topic.progress, height: 8),
                        const SizedBox(height: 12),
                        ...topic.lessons.asMap().entries.map((entry) {
                          final lesson = entry.value;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundColor: AppPreferences.palette.value.primary.withOpacity( .10), child: Text('${entry.key + 1}', style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900))),
                            title: Text(lesson.title, style: TextStyle(fontWeight: FontWeight.w800, color: lesson.locked ? AppColors.muted : AppColors.ink)),
                            subtitle: Text(lesson.locked ? 'Locked' : lesson.duration),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: lesson.locked
                                ? null
                                : () => Navigator.pushNamed(context, RouteNames.lessonDetail, arguments: {'subjectId': subject.id, 'topicId': topic.id, 'lessonId': lesson.id}),
                          );
                        }),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
