import 'dart:async';
import '../presentation/widgets/animated_background.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

final _primary = Color(0xFF2563EB);
final _secondary = Color(0xFF14B8A6);
final _chip = Color(0xFFEFF6FF);

final _ink = Color(0xFF242033);
final _muted = Color(0xFF8C879A);

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
    final _secondary = _palette.secondary;
    final _gBackgroundStart = _palette.background.first;
    final _chip =
        Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    final concept = LocalContentService().getConcept(
      widget.subjectId,
      widget.topicId,
      widget.lessonId,
      widget.conceptId,
    );
    final problem = concept.problem;
    final choices = problem.choices.isEmpty
        ? [
            problem.answer,
            'x = 1 and x = 3/2',
            'x = -2 and x = 3',
            'No solution'
          ]
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
    const appBarHeight =
        74.0; // MathivaAppBar.preferredSize when subtitle != null
    const appBarBottomBorder = 1.0;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = statusBarHeight + appBarHeight + appBarBottomBorder + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: '${widget.difficulty} Practice',
        subtitle: 'Choose your answer carefully',
        icon: Icons.edit_note_rounded,
        onBack: () => context.canPop() ? context.pop() : context.go('/concept'),
        actions: [
          IconButton(
            tooltip: 'Ask Math Tutor',
            onPressed: () => context.push(RouteNames.chat),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            color: _primary,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBackground(
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
              _GradientButton(
                label: 'Submit Answer',
                onPressed:
                    _selected == null ? null : () => _submit(problem.answer),
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
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;
    final _secondary = _palette.secondary;
    final _gBackgroundStart = _palette.background.first;
    final _chip =
        Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _primary : const Color(0xFFF1ECFF)),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(selected ? .12 : .06),
                blurRadius: 8,
                offset: const Offset(0, 8),
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
                  color: selected ? _primary : _chip,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: const Color(0xFFF7F9FC), size: 16)
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
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;
    final _secondary = _palette.secondary;
    final _gBackgroundStart = _palette.background.first;
    final _chip =
        Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _chip),
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
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;
    final _secondary = _palette.secondary;
    final _gBackgroundStart = _palette.background.first;
    final _chip =
        Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration:
          BoxDecoration(color: _chip, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
    );
  }
}

// Minimal outline button — no fill, no shadow. Renamed from
// `_GradientButton` would change the public surface other files might
// reference by name, so the class name is left as-is; only the visual
// treatment changed to match the rest of the app's new outline style.
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;
    final _secondary = _palette.secondary;
    final _gBackgroundStart = _palette.background.first;
    final _chip =
        Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    final isDisabled = onPressed == null;
    final accentColor = isDisabled ? const Color(0xFFB4B2A9) : _primary;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: accentColor,
          disabledForegroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 1),
          shadowColor: Colors.transparent,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final _palette = AppPreferences.palette.value;
    final _primary = _palette.primary;
    final _chip =
        Color.alphaBlend(_primary.withOpacity(0.05), const Color(0xFFF7F9FC));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1ECFF)),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 9,
            offset: const Offset(0, 8),
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
