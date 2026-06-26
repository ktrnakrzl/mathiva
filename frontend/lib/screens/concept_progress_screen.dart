import 'package:flutter/material.dart';
import '../presentation/widgets/atmosphere_background.dart';
import '../presentation/widgets/tap_scale.dart';
import '../presentation/widgets/primary_button.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../utils/route_names.dart';

// ── Design tokens (mirrors HomeScreen exactly) ────────────────────────────────
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);
const _headerTint = Color(0xFFF6F2FF);

class ConceptProgressScreen extends StatelessWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  const ConceptProgressScreen({super.key, required this.subjectId, required this.topicId, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    final primary = palette.primary;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _headerTint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: false,
        toolbarHeight: 56,
        titleSpacing: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
          onPressed: () => context.canPop() ? context.pop() : context.go('/lesson-detail'),
        ),
        title: const Text(
          'Concept Progress',
          style: TextStyle(
            color: Color(0xFF312E81),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            height: 1,
          ),
        ),
      ),
      body: AtmosphereBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            physics: const BouncingScrollPhysics(),
            children: [
              _SoftCard(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.rocket_launch_rounded, color: primary, size: 26),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Concept Progress',
                      style: TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text('28% Completed', style: TextStyle(color: _muted, fontSize: 13)),
                    const SizedBox(height: 18),
                    _ProgressBar(value: .28, primary: primary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Metric(label: 'Best Time', value: '1m 58s', icon: Icons.timer_rounded, primary: primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _Metric(label: 'Accuracy', value: '100%', icon: Icons.check_circle_rounded, primary: primary)),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Back to Concepts',
                onPressed: () => context.canPop() ? context.pop() : context.go('/lesson-detail'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color primary;
  const _Metric({required this.label, required this.value, required this.icon, required this.primary});

  @override
  Widget build(BuildContext context) => _SoftCard(
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: primary, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: _muted, fontSize: 11.5)),
          ],
        ),
      );
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color primary;
  const _ProgressBar({required this.value, required this.primary});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 6,
          backgroundColor: _border,
          valueColor: AlwaysStoppedAnimation<Color>(primary),
        ),
      );
}

// ── Soft card ─────────────────────────────────────────────────────────────────

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}