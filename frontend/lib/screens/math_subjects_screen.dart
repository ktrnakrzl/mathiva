import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/progress_line.dart';
import '../widgets/section_card.dart';

class MathSubjectsScreen extends StatelessWidget {
  const MathSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = LocalContentService().getSubjects();
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            const AppHeader(title: 'Math Subjects', subtitle: 'Senior High School Mathematics only'),
            const SizedBox(height: 18),
            const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search subject or topic')),
            const SizedBox(height: 18),
            ...subjects.map((subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SectionCard(
                    onTap: () => Navigator.pushNamed(context, RouteNames.lessons, arguments: {'subjectId': subject.id}),
                    child: Row(
                      children: [
                        Container(
                          height: 58,
                          width: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppPreferences.palette.value.primary, AppPreferences.palette.value.secondary]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(child: Text(subject.iconText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('${subject.gradeLevel} - ${subject.topics.length} topics', style: const TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 8),
                              ProgressLine(percent: subject.progress, height: 7),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
