import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/progress_line.dart';
import '../widgets/section_card.dart';

class ConceptProgressScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;

  const ConceptProgressScreen({super.key, required this.subjectId, required this.topicId, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
              child: Icon(Icons.rocket_launch_rounded, color: AppPreferences.palette.value.primary, size: 72),
            ),
            const SizedBox(height: 22),
            const Text('Concept Progress', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('28% Completed', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            const ProgressLine(percent: 28, height: 12),
            const SizedBox(height: 24),
            Row(
              children: const [
                Expanded(child: _MetricCard(title: 'Best Time', value: '1m 58s', icon: Icons.timer_rounded)),
                SizedBox(width: 12),
                Expanded(child: _MetricCard(title: 'Accuracy', value: '100%', icon: Icons.check_circle_rounded)),
              ],
            ),
            const SizedBox(height: 26),
            GradientButton(
              label: 'Back to Concepts',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.lessonDetail,
                ModalRoute.withName(RouteNames.home),
                arguments: {'subjectId': subjectId, 'topicId': topicId, 'lessonId': lessonId},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          Icon(icon, color: AppPreferences.palette.value.primary),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
