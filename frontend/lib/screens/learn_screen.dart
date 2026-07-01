import 'package:flutter/material.dart';

import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';
import '../presentation/widgets/animated_background.dart';
import '../theme/app_theme.dart';
import '../theme/semantic_colors.dart';
import 'math_subjects_screen.dart';
import 'progress_overview_screen.dart';

/// The merged "Learn" tab. Hosts the Lessons subject list and the Progress
/// overview under a single bottom-nav destination, switched by a shadcn-style
/// segmented control. Merging the two keeps the bottom bar at five items with
/// the raised "Scan" action perfectly centered.
///
/// Both segments are the existing standalone screens rendered in `embedded`
/// mode (body only — no Scaffold/top bar/nav), so their pushed routes
/// (`/subjects`, `/progress`) keep working unchanged elsewhere in the app.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _segment = 0; // 0 = Lessons, 1 = Progress

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.pageBg,
      appBar: const MathivaTopBar(),
      body: AnimatedBackground(
        vivid: true,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
                child: _Segmented(
                  index: _segment,
                  onChanged: (i) => setState(() => _segment = i),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _segment,
                  children: const [
                    MathSubjectsScreen(embedded: true),
                    ProgressOverviewScreen(embedded: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.learn),
    );
  }
}

// ─── Segmented control ──────────────────────────────────────────────────────
// A muted pill track with two segments; the selected one is lifted onto an
// elevated surface (page-bg fill + soft shadow) with ink text, the other stays
// flat and muted — the standard shadcn "tabs" treatment.
class _Segmented extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _Segmented({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.pillBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        children: [
          _seg(context, colors, label: 'Lessons', segment: 0),
          _seg(context, colors, label: 'Progress', segment: 1),
        ],
      ),
    );
  }

  Widget _seg(
    BuildContext context,
    SemanticColors colors, {
    required String label,
    required int segment,
  }) {
    final selected = index == segment;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(segment),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.pageBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.ink : colors.muted,
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
