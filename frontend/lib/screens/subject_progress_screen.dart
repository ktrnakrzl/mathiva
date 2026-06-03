import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/progress_line.dart';
import '../widgets/section_card.dart';

class SubjectProgressScreen extends StatelessWidget {
  final String subjectId;
  const SubjectProgressScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final subject = LocalContentService().getSubject(subjectId);
    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(title: subject.title, subtitle: '34/50 Lessons completed'),
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Expanded(child: Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w900))), Text('${subject.progress}%', style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900))]),
                  const SizedBox(height: 10),
                  ProgressLine(percent: subject.progress),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(child: _SmallStat(label: 'Study Time', value: '2h 15m')),
                      Expanded(child: _SmallStat(label: 'Avg. Time', value: '2m 05s')),
                      Expanded(child: _SmallStat(label: 'Accuracy', value: '82%')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('Topic Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...subject.topics.map((topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    onTap: () => Navigator.pushNamed(context, RouteNames.topicAnalytics, arguments: {'subjectId': subject.id, 'topicId': topic.id}),
                    child: Row(
                      children: [
                        Icon(Icons.pie_chart_rounded, color: AppPreferences.palette.value.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const Text('Lessons completed', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                              const SizedBox(height: 8),
                              ProgressLine(percent: topic.progress, height: 7),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${topic.progress}%', style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900)),
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

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}
