import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/data/models/subject_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);

final topicsProvider = FutureProvider.family<List<Topic>, String>((ref, subjectId) {
  return ref.read(subjectRepositoryProvider).getTopics(subjectId);
});

class TopicListScreen extends ConsumerWidget {
  final String subjectId;
  const TopicListScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider(subjectId));
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Topics',
        subtitle: 'Pick a topic',
        icon: Icons.list_alt_rounded,
        showBack: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: topics.when(
            data: (items) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 28),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const SectionHeader(
                    title: 'Topics',
                    subtitle: 'Pick a topic to practice',
                  );
                }
                final topic = items[index - 1];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 60 * index),
                  child: _SoftCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(topic.name, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: topic.difficulty_available.map((value) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [palette.primary.withOpacity(.14), palette.secondary.withOpacity(.14)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(value, style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800)),
                            )).toList(),
                      ),
                    ]),
                  ),
                );
              },
            ),
            loading: () => const LoadingOverlay(),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC).withOpacity(.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: child,
      );
}
