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

final masteryProvider = FutureProvider<List<TopicMastery>>((ref) {
  return ref.read(progressRepositoryProvider).getMastery(AppStrings.studentId);
});

class MasteryHeatmapScreen extends ConsumerWidget {
  const MasteryHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(masteryProvider);
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Mastery Heatmap',
        subtitle: 'Visualize your progress',
        icon: Icons.grid_view_rounded,
        showBack: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: mastery.when(
            data: (items) => CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Mastery',
                      subtitle: 'Your strength across topics',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.15,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 60 * index),
                          child: _SoftCard(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Text(item.topic_name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: _ink,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 10),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        palette.primary,
                                        palette.secondary
                                      ]).createShader(bounds),
                                  child: Text('${item.mastery_level}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(height: 8),
                                _ProgressBar(
                                    value: item.mastery_level / 100,
                                    color: palette.primary),
                                const SizedBox(height: 8),
                                Text('Last: ${item.last_practiced}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: _muted, fontSize: 11)),
                              ])),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
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

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ProgressBar({required this.value, required this.color});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 9,
              backgroundColor: _chip,
              valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      );
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC).withOpacity(.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))
          ],
        ),
        child: child,
      );
}
