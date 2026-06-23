import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/presentation/notifiers/progress_notifier.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/presentation/widgets/tap_scale.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);
const _chip = Color(0xFFEDE9FF);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(progressNotifierProvider.notifier).loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressNotifierProvider);
    final palette = AppPreferences.palette.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: MathivaAppBar(
        title: 'Mathivia',
        subtitle: 'Ready to learn?',
        icon: Icons.auto_awesome_rounded,
        showBack: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: state.when(
            data: (progress) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 96, 16, 28),
              physics: const BouncingScrollPhysics(),
              children: [
                if (progress != null)
                  FadeSlideIn(
                    child: _SoftCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [palette.primary, palette.secondary],
                            ).createShader(bounds),
                            child: Text(
                              '${progress.points_total} pts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  color: Color(0xFFFF922B), size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${progress.streak_days} day streak',
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
                    title: 'Quick Actions',
                    subtitle: 'Jump back into learning',
                  ),
                ),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.18,
                  children: [
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: const _HomeTile(
                          title: 'Subjects',
                          icon: Icons.menu_book_rounded,
                          route: '/subjects'),
                    ),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      child: const _HomeTile(
                          title: 'Tutor',
                          icon: Icons.chat_bubble_outline_rounded,
                          route: '/tutor'),
                    ),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: const _HomeTile(
                          title: 'Quiz',
                          icon: Icons.quiz_rounded,
                          route: '/quiz'),
                    ),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 270),
                      child: const _HomeTile(
                          title: 'Rewards',
                          icon: Icons.emoji_events_rounded,
                          route: '/rewards'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: const SectionHeader(
                    title: 'Continue Learning',
                    subtitle: 'Pick up where you left off',
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
                  child: _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Functions • Introduction',
                          style: TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 14),
                        _ProgressBar(value: .64),
                      ],
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

class _HomeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;

  const _HomeTile({
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return TapScale(
      onTap: () => context.go(route),
      child: _SoftCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.primary.withOpacity(.16),
                    palette.secondary.withOpacity(.16),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: palette.primary, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) => LinearProgressIndicator(
          value: animatedValue,
          minHeight: 10,
          backgroundColor: _chip,
          valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SoftCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC).withOpacity(.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return TapScale(onTap: onTap, child: card);
  }
}
