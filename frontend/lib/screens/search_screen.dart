import 'package:flutter/material.dart';
import '../services/app_preferences.dart';

import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/app_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/section_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LocalContentService();
    final topics = service.allTopics();
    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: 'Search', subtitle: 'Find lessons, formulas, and topics'),
            const SizedBox(height: 18),
            const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Type a keyword')),
            const SizedBox(height: 14),
            Row(
              children: const [
                _Pill(label: 'All', active: true),
                SizedBox(width: 8),
                _Pill(label: 'Lessons'),
                SizedBox(width: 8),
                _Pill(label: 'Formulas'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _SearchChip(label: 'Quadratic Equations'),
                _SearchChip(label: 'Limits'),
                _SearchChip(label: 'Probability'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Popular Lessons', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            ...topics.take(5).map((topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    onTap: () {
                      final subject = service.getSubjects().firstWhere((s) => s.topics.contains(topic));
                      Navigator.pushNamed(context, RouteNames.lessons, arguments: {'subjectId': subject.id});
                    },
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_rounded, color: AppPreferences.palette.value.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                        const Icon(Icons.chevron_right_rounded),
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

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  const _Pill({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(color: active ? AppPreferences.palette.value.primary : Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w800)),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  const _SearchChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), backgroundColor: Colors.white, side: BorderSide.none);
  }
}
