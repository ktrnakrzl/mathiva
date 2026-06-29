import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/app_strings.dart';
import 'package:mathiva/data/models/progress_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/glass_card.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/services/app_preferences.dart';
import 'package:mathiva/theme/app_theme.dart';
import '../../../widgets/mathiva_app_bar.dart';

final masteryProvider = FutureProvider<List<TopicMastery>>((ref) {
  return ref.read(progressRepositoryProvider).getMastery(AppStrings.studentId);
});

class MasteryHeatmapScreen extends ConsumerWidget {
  const MasteryHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(masteryProvider);
    final palette = AppPreferences.palette.value;
    final colors = AppTheme.colorsOf(context);
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
        vivid: true,
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
                          child: GlassCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Text(item.topic_name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: colors.ink,
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
                                    style: TextStyle(
                                        color: colors.muted, fontSize: 11)),
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
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 9,
            backgroundColor: colors.glassBorderSoft,
            valueColor: AlwaysStoppedAnimation<Color>(color)),
      ),
    );
  }
}
