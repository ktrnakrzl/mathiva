import 'package:flutter/material.dart';
import '../presentation/widgets/animated_background.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../utils/route_names.dart';

final _primary = Color(0xFF2563EB);
final _secondary = Color(0xFF14B8A6);
final _chip = Color(0xFFEFF6FF);

final _ink = Color(0xFF242033);
final _muted = Color(0xFF8C879A);

class ConceptProgressScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  const ConceptProgressScreen({super.key, required this.subjectId, required this.topicId, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;
    final _chip = Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
                      onPressed: () => context.canPop() ? context.pop() : context.go('/lesson-detail'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _SoftCard(
                      child: Column(
                        children: [
                          Icon(Icons.rocket_launch_rounded, color: _primary, size: 72),
                          SizedBox(height: 16),
                          Text('Concept Progress', style: TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text('28% Completed', style: TextStyle(color: _muted)),
                          SizedBox(height: 18),
                          _ProgressBar(value: .28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        Expanded(child: _Metric(label: 'Best Time', value: '1m 58s', icon: Icons.timer_rounded)),
                        SizedBox(width: 12),
                        Expanded(child: _Metric(label: 'Accuracy', value: '100%', icon: Icons.check_circle_rounded)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _GradientButton(
                      label: 'Back to Concepts',
                      onPressed: () => context.canPop() ? context.pop() : context.go('/lesson-detail'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => _SoftCard(
        child: Column(
          children: [
            Icon(icon, color: _primary),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      );
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) => ClipRRect(
        child: LinearProgressIndicator(
          value: value,
          minHeight: 12,
          backgroundColor: _chip,
          valueColor: AlwaysStoppedAnimation<Color>(_primary),
        ),
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: _primary,
            side: BorderSide(color: _primary, width: 1),
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 8))],
        ),
        child: child,
      );
}

// REDESIGNED SCREEN MARKER
