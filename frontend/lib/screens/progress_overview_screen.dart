import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/local_content_service.dart';
import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/progress_line.dart';

class ProgressOverviewScreen extends StatefulWidget {
  const ProgressOverviewScreen({super.key});

  @override
  State<ProgressOverviewScreen> createState() => _ProgressOverviewScreenState();
}

class _ProgressOverviewScreenState extends State<ProgressOverviewScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = LocalContentService().getSubjects();
    final average = subjects.isEmpty ? 0 : (subjects.map((s) => s.progress).reduce((a, b) => a + b) / subjects.length).round();
    final palette = AppPreferences.palette.value;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.background,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -70, left: -65, child: _GlowBlob(size: 190, color: palette.secondary.withOpacity(.38))),
            Positioned(top: 180, right: -90, child: _GlowBlob(size: 220, color: palette.primary.withOpacity(.28))),
            Positioned(bottom: 20, left: -80, child: _GlowBlob(size: 230, color: palette.secondary.withOpacity(.22))),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 148),
                physics: const BouncingScrollPhysics(),
                children: [
                  _AnimatedIn(
                    animation: _controller,
                    intervalStart: 0,
                    child: _Header(average: average),
                  ),
                  const SizedBox(height: 22),
                  _AnimatedIn(
                    animation: _controller,
                    intervalStart: .10,
                    child: _OverallCard(average: average),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _AnimatedIn(animation: _controller, intervalStart: .18, child: const _SummaryCard(label: 'Lessons Done', value: '34/50', percent: 68, icon: Icons.menu_book_rounded)),
                      _AnimatedIn(animation: _controller, intervalStart: .24, child: const _SummaryCard(label: 'Practice Done', value: '6/10', percent: 60, icon: Icons.task_alt_rounded)),
                      _AnimatedIn(animation: _controller, intervalStart: .30, child: const _SummaryCard(label: 'Study Time', value: '2h 15m', percent: 45, icon: Icons.schedule_rounded)),
                      _AnimatedIn(animation: _controller, intervalStart: .36, child: const _SummaryCard(label: 'Avg. Speed', value: '2m 05s', percent: 58, icon: Icons.timer_rounded)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _AnimatedIn(
                    animation: _controller,
                    intervalStart: .42,
                    child: const Text('Subject Progress', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ),
                  const SizedBox(height: 12),
                  for (int index = 0; index < subjects.length; index++) ...[
                    _AnimatedIn(
                      animation: _controller,
                      intervalStart: .48 + (index * .06),
                      child: _SubjectProgressCard(
                        title: subjects[index].title,
                        iconText: subjects[index].iconText,
                        percent: subjects[index].progress,
                        onTap: () => Navigator.pushNamed(context, RouteNames.subjectProgress, arguments: {'subjectId': subjects[index].id}),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  _AnimatedIn(
                    animation: _controller,
                    intervalStart: .70,
                    child: const _WeeklyActivityCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.progress),
    );
  }
}

class _Header extends StatelessWidget {
  final int average;

  const _Header({required this.average});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Your Progress', style: TextStyle(fontSize: 30, height: 1.05, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -.5)),
              SizedBox(height: 8),
              Text('See what you finished and what to review next.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppPreferences.palette.value.secondary, AppPreferences.palette.value.primary]),
            shape: BoxShape.circle,
                      ),
          alignment: Alignment.center,
          child: Text('$average%', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  final int average;

  const _OverallCard({required this.average});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: AppPreferences.palette.value.primary, size: 28),
              SizedBox(width: 10),
              Text('Overall Learning Progress', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 14),
          Text('$average% complete', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 10),
          ProgressLine(percent: average, height: 10),
          const SizedBox(height: 10),
          const Text('This is the average progress from all math subjects. Tap a subject below for details.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final int percent;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.percent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppPreferences.palette.value.primary, size: 28),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.ink)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          ProgressLine(percent: percent, height: 6),
        ],
      ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final String title;
  final String iconText;
  final int percent;
  final VoidCallback onTap;

  const _SubjectProgressCard({required this.title, required this.iconText, required this.percent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppPreferences.palette.value.primary.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
                child: Text(iconText, style: TextStyle(color: AppPreferences.palette.value.primary, fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                    const SizedBox(height: 9),
                    ProgressLine(percent: percent, height: 8),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('$percent%', style: TextStyle(color: AppPreferences.palette.value.primary, fontWeight: FontWeight.w900)),
              Icon(Icons.chevron_right_rounded, color: AppPreferences.palette.value.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Bar(day: 'M', height: 48),
              _Bar(day: 'T', height: 72),
              _Bar(day: 'W', height: 38),
              _Bar(day: 'T', height: 90),
              _Bar(day: 'F', height: 64),
              _Bar(day: 'S', height: 44),
              _Bar(day: 'S', height: 80),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String day;
  final double height;

  const _Bar({required this.day, required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 18,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPreferences.palette.value.secondary, AppPreferences.palette.value.primary]),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity( .92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity( .95)),
              ),
      child: child,
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  final Animation<double> animation;
  final double intervalStart;
  final Widget child;

  const _AnimatedIn({required this.animation, required this.intervalStart, required this.child});

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(math.max(0.0, math.min(intervalStart, .92)), 1, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - curved.value)),
            child: Transform.scale(scale: .97 + (.03 * curved.value), alignment: Alignment.topCenter, child: child),
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity( .50), ),
      ),
    );
  }
}
