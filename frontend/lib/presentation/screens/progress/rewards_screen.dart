import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/data/models/progress_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);
const _chip = Color(0xFFEDE9FF);

final rewardsProvider = FutureProvider<Rewards>((ref) {
  return ref.read(progressRepositoryProvider).getRewards(AppStrings.studentId);
});

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final palette = AppPreferences.palette.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Rewards',
        subtitle: 'Your achievements',
        icon: Icons.emoji_events_rounded,
        showBack: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: rewards.when(
            data: (data) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 28),
              physics: const BouncingScrollPhysics(),
              children: [
                const SectionHeader(
                  title: 'Rewards',
                  subtitle: 'Your points & achievements',
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [palette.primary, palette.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Points',
                          style: TextStyle(color: Colors.white.withOpacity(.8), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data.points}',
                          style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text('Rank: ${data.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: const SectionHeader(
                    title: 'Badges',
                    subtitle: 'Collected through your journey',
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                ),
                ...data.badges.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final badge = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FadeSlideIn(
                        delay: Duration(milliseconds: 120 + 60 * index),
                        child: _SoftCard(
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [palette.primary.withOpacity(.16), palette.secondary.withOpacity(.16)]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.emoji_events_rounded, color: palette.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(badge.name, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 15)),
                                    Text('Earned: ${badge.earned_date}', style: const TextStyle(color: _muted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
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
