import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/presentation/notifiers/progress_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/points_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(progressNotifierProvider.notifier).loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mathiva Dashboard')),
      body: state.when(
        data: (progress) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (progress != null) PointsBar(points: progress.points_total, streakDays: progress.streak_days),
            const SizedBox(height: 12),
            const _HomeTile(title: 'Subjects', subtitle: 'Choose a Mathiva subject', route: '/subjects'),
            const _HomeTile(title: 'Tutor', subtitle: 'Ask the RAG math tutor', route: '/tutor'),
            const _HomeTile(title: 'Quiz', subtitle: 'Practice with adaptive questions', route: '/quiz'),
            const _HomeTile(title: 'Review Queue', subtitle: 'Spaced repetition review', route: '/review'),
            const _HomeTile(title: 'Mastery', subtitle: 'Track topic mastery', route: '/mastery'),
            const _HomeTile(title: 'Rewards', subtitle: 'View points and badges', route: '/rewards'),
          ],
        ),
        loading: () => const LoadingOverlay(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String route;
  const _HomeTile({required this.title, required this.subtitle, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }
}
