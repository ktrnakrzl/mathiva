import 'dart:async';
import '../presentation/widgets/atmosphere_background.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';
import '../presentation/widgets/primary_button.dart';
import '../presentation/widgets/tap_scale.dart';

// ── Design tokens (mirrors HomeScreen exactly) ────────────────────────────────
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

class PracticeScreen extends StatefulWidget {
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;
  final String difficulty;

  const PracticeScreen({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
    required this.conceptId,
    required this.difficulty,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String? _selected;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submit(String correctAnswer) {
    final selected = _selected;
    if (selected == null) return;
    _timer?.cancel();

    final correct = selected == correctAnswer;
    if (AppPreferences.hapticFeedback.value) {
      if (correct) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    }

    context.push(
      RouteNames.result,
      extra: {
        'subjectId': widget.subjectId,
        'topicId': widget.topicId,
        'lessonId': widget.lessonId,
        'conceptId': widget.conceptId,
        'difficulty': widget.difficulty,
        'selectedAnswer': selected,
        'elapsedSeconds': _elapsedSeconds,
        'isCorrect': correct,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;

    final concept = LocalContentService().getConcept(
      widget.subjectId,
      widget.topicId,
      widget.lessonId,
      widget.conceptId,
    );
    final problem = concept.problem;
    final choices = problem.choices.isEmpty
        ? [problem.answer, 'x = 1 and x = 3/2', 'x = -2 and x = 3', 'No solution']
        : problem.choices;

    // The screen uses `extendBodyBehindAppBar: true` + `SafeArea(top:
    // false)` so the scrolling background shows through behind the
    // translucent-feeling app bar. That means the ListView itself has to
    // account for *all* of the space the app bar visually occupies —
    // status bar height + the app bar's own height (including its
    // bottom hairline) — before the real content starts.
    //
    // MathivaAppBar is taller when it has a subtitle (74 vs 58) plus a
    // 1px bottom border, and this screen always passes a subtitle. A
    // hardcoded `86` doesn't track that, and on devices with a taller
    // status bar it ends up too small, letting the app bar visually
    // overlap/clip the first chunk of scrollable content (which is what
    // was happening — the list *was* scrolling, it just started from
    // underneath the header).
    const appBarHeight = 68.0; // MathivaAppBar.preferredSize when subtitle != null
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = statusBarHeight + appBarHeight + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: '${widget.difficulty} Practice',
        subtitle: 'Choose your answer carefully',
        icon: Icons.edit_note_rounded,
        onBack: () => context.canPop() ? context.pop() : context.go('/concept'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _HeaderIconAction(
              icon: Icons.chat_bubble_outline_rounded,
              tooltip: 'Ask Math Tutor',
              onTap: () => context.push(RouteNames.chat),
              primary: _primary,
            ),
          ),
        ],
      ),
      body: AtmosphereBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 28),
            physics: const BouncingScrollPhysics(),
            children: [
              _SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Pill(label: 'Question 1 of 1'),
                        const Spacer(),
                        _TimerBadge(seconds: _elapsedSeconds),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      problem.question,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose an answer. The next screen will show the solution and why it works.',
                      style: TextStyle(color: _muted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChoiceTile(
                    label: choice,
                    selected: _selected == choice,
                    onTap: () => setState(() => _selected = choice),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Submit Answer',
                onPressed: _selected == null ? null : () => _submit(problem.answer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final _primary = AppPreferences.palette.value.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _primary : _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _primary : _border,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? _primary : _ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int seconds;

  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final _primary = AppPreferences.palette.value.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: _primary),
          const SizedBox(width: 5),
          Text(
            _formatTimer(seconds),
            style: TextStyle(color: _primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final _primary = AppPreferences.palette.value.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

String _formatTimer(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}

// ── Header Icon Action ────────────────────────────────────────────────────────
class _HeaderIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color primary;

  const _HeaderIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 19),
        ),
      ),
    );
  }
}