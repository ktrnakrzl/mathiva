import 'package:flutter/material.dart';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/glass_card.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../theme/app_theme.dart';
import '../utils/duration_format.dart';

class ConceptProgressScreen extends StatefulWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String? conceptId;
  const ConceptProgressScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
    this.conceptId,
  });

  @override
  State<ConceptProgressScreen> createState() => _ConceptProgressScreenState();
}

class _ConceptProgressScreenState extends State<ConceptProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Pull fresh stats; the just-submitted attempt may already have landed.
    ProgressStore.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      body: AnimatedBackground(
        vivid: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: primary),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/lesson-detail'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<UserProgress?>(
                  valueListenable: ProgressStore.current,
                  builder: (context, progress, _) {
                    // Concept-level stat for the concept we navigated from.
                    // Null conceptId (older nav paths) or no attempts yet ->
                    // genuine zero-state.
                    final conceptId = widget.conceptId;
                    final stat = (progress != null && conceptId != null)
                        ? progress.conceptStats[conceptId]
                        : null;
                    final bestTime = (progress != null && conceptId != null)
                        ? _bestTimeFor(progress, conceptId)
                        : null;

                    final accuracy = stat?.accuracy ?? 0;
                    final hasData = stat != null && stat.attempts > 0;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        GlassCard(
                          child: Column(
                            children: [
                              Icon(Icons.rocket_launch_rounded,
                                  color: primary, size: 72),
                              const SizedBox(height: 16),
                              Text('Concept Progress',
                                  style: TextStyle(
                                      color: colors.ink,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                hasData
                                    ? '${accuracy.round()}% Accuracy'
                                    : 'No data yet',
                                style: TextStyle(color: colors.muted),
                              ),
                              const SizedBox(height: 18),
                              _ProgressBar(value: accuracy / 100),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Best Time',
                                value: bestTime != null
                                    ? formatElapsed(bestTime)
                                    : '—',
                                icon: Icons.timer_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Metric(
                                label: 'Accuracy',
                                value: hasData ? '${accuracy.round()}%' : '—',
                                icon: Icons.check_circle_rounded,
                              ),
                            ),
                          ],
                        ),
                        if (hasData) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${stat.correct} of ${stat.attempts} attempt'
                            '${stat.attempts == 1 ? '' : 's'} correct',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: colors.muted, fontSize: 12.5),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _GradientButton(
                          label: 'Back to Concepts',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/lesson-detail'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _bestTimeFor(UserProgress progress, String conceptId) {
    for (final b in progress.bestTimeByConcept) {
      if (b.conceptId == conceptId) return b.bestElapsedSeconds;
    }
    return null;
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: primary),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: colors.ink, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: colors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return ClipRRect(
      child: LinearProgressIndicator(
        value: value,
        minHeight: 12,
        backgroundColor: colors.glassBorderSoft,
        valueColor: AlwaysStoppedAnimation<Color>(primary),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
