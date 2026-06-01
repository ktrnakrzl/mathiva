import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/data/models/progress_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';

final rewardsProvider = FutureProvider<Rewards>((ref) {
  return ref.read(progressRepositoryProvider).getRewards(AppStrings.studentId);
});

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: rewards.when(
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(title: Text('Points: ${data.points}'), subtitle: Text('Rank: ${data.rank}')),
            ),
            ...data.badges.map((badge) => Card(
                  child: ListTile(title: Text(badge.name), subtitle: Text('Earned: ${badge.earned_date}')),
                )),
          ],
        ),
        loading: () => const LoadingOverlay(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
