import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/progress_line.dart';
import '../widgets/section_card.dart';

class TopicAnalyticsScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;

  const TopicAnalyticsScreen({super.key, required this.subjectId, required this.topicId});

  @override
  Widget build(BuildContext context) {
    final topic = LocalContentService().getTopic(subjectId, topicId);
    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(title: topic.title, subtitle: 'Topic analytics'),
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Expanded(child: Text('8/14 Lessons completed', style: TextStyle(fontWeight: FontWeight.w900))), Text('${topic.progress}%', style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900))]),
                  const SizedBox(height: 10),
                  ProgressLine(percent: topic.progress),
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
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance Overview', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 16),
                  const Center(child: _DonutMock()),
                  const SizedBox(height: 16),
                  _LegendRow(label: 'Correct', value: '82% / 65', color: AppPreferences.palette.value.primary),
                  _LegendRow(label: 'Incorrect', value: '12% / 10', color: AppPreferences.palette.value.secondary),
                  _LegendRow(label: 'Skipped', value: '6% / 5', color: AppPreferences.palette.value.primary.withOpacity(.55)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Difficulty Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(child: _DifficultyCard(label: 'Easy', value: '90%', caption: '27/30')),
                SizedBox(width: 10),
                Expanded(child: _DifficultyCard(label: 'Medium', value: '75%', caption: '30/40')),
                SizedBox(width: 10),
                Expanded(child: _DifficultyCard(label: 'Hard', value: '60%', caption: '12/20')),
              ],
            ),
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Weak Topics', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 10),
                  _WeakTopic(label: 'Factoring', percent: 62),
                  _WeakTopic(label: 'Word Problems', percent: 48),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(label: 'Practice Weak Topics', onPressed: () => Navigator.pop(context)),
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
    return Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11))]);
  }
}

class _DonutMock extends StatelessWidget {
  const _DonutMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: 140,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppPreferences.palette.value.primary, width: 22)),
      child: Center(child: Text('82%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: AppPreferences.palette.value.primary))),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LegendRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [CircleAvatar(radius: 6, backgroundColor: color), const SizedBox(width: 8), Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  const _DifficultyCard({required this.label, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(value, style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900, fontSize: 20)), Text('$caption correct', style: const TextStyle(color: AppColors.muted, fontSize: 11))]),
    );
  }
}

class _WeakTopic extends StatelessWidget {
  final String label;
  final int percent;
  const _WeakTopic({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), Text('$percent%', style: TextStyle(color: AppPreferences.palette.value.secondary, fontWeight: FontWeight.w900))]),
    );
  }
}
