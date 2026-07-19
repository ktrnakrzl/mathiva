import 'dart:async';
import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/glass_card.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

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
  // The server-generated question for this concept. Null until it loads.
  GeneratedQuestion? _question;
  bool _loadingQuestion = true;
  String? _loadError;
  // True when the load failed with 401 -- the session expired, so the fix is
  // to log in again (not "try again" with the same dead token).
  bool _sessionExpired = false;

  String? _selected;
  bool _submitting = false;

  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Fetches a fresh question from the server. The timer only starts once the
  /// question is on screen, so loading time isn't counted against the student.
  Future<void> _loadQuestion() async {
    setState(() {
      _loadingQuestion = true;
      _loadError = null;
      _sessionExpired = false;
      _selected = null;
    });
    try {
      // Adaptive: the server picks the difficulty from THIS student's history on
      // the concept (see /api/quiz/next-adaptive) instead of the client dictating
      // it. The pool is the concept the student opened, so a strong student gets
      // a harder question and a struggling one gets an easier one automatically.
      final question = await ProgressService.fetchAdaptiveQuestion(
        subjectId: widget.subjectId,
        topicId: widget.topicId,
        lessonId: widget.lessonId,
        candidateConcepts: [widget.conceptId],
      );
      if (!mounted) return;
      setState(() {
        _question = question;
        _loadingQuestion = false;
        _elapsedSeconds = 0;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds++);
      });
    } catch (e) {
      if (!mounted) return;
      final status = e is DioException ? e.response?.statusCode : null;
      // 422 means there's no question template for this concept yet -- a
      // content gap, not a transient failure, so say so plainly.
      // 401 means the login session expired (the JWT only lasts 24h) -- the
      // fix is to sign in again, not to retry with the same dead token.
      final sessionExpired = status == 401;
      setState(() {
        _loadingQuestion = false;
        _sessionExpired = sessionExpired;
        if (sessionExpired) {
          _loadError = 'Your session expired. Please log in again.';
        } else if (status == 422) {
          _loadError = "Practice questions for this lesson aren't ready yet.";
        } else {
          _loadError =
              "Couldn't load a question. Check your connection and try again.";
        }
      });
    }
  }

  Future<void> _submit() async {
    final selected = _selected;
    final question = _question;
    if (selected == null || question == null || _submitting) return;

    _timer?.cancel();
    setState(() => _submitting = true);

    final AnswerResult result;
    try {
      result = await ProgressService.submitAnswer(
        questionId: question.questionId,
        selectedAnswer: selected,
        elapsedSeconds: _elapsedSeconds,
      );
    } catch (_) {
      if (!mounted) return;
      // Submit failed -- let the student try again rather than losing their
      // answer. Resume the timer so elapsed time stays honest.
      setState(() => _submitting = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds++);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't submit your answer. Try again.")),
      );
      return;
    }

    if (AppPreferences.hapticFeedback.value) {
      if (result.isCorrect) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    }

    // The attempt is already recorded server-side by /api/quiz/answer; refresh
    // the local stats cache so the progress screens reflect it next time.
    unawaited(ProgressStore.refresh());

    if (!mounted) return;
    context.push(
      RouteNames.result,
      extra: {
        'subjectId': widget.subjectId,
        'topicId': widget.topicId,
        'lessonId': widget.lessonId,
        // The concept + difficulty the SERVER actually served (adaptive), not
        // whatever the client requested -- so the result screen and any retry
        // reflect what the student really practiced.
        'conceptId': question.conceptId,
        'difficulty': question.difficulty,
        'selectedAnswer': selected,
        'elapsedSeconds': _elapsedSeconds,
        'isCorrect': result.isCorrect,
        'correctAnswer': result.correctAnswer,
        'steps': result.steps,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    // The screen uses `extendBodyBehindAppBar: true` + `SafeArea(top:
    // false)` so the scrolling background shows through behind the
    // translucent-feeling app bar. The body content has to account for all
    // of the space the app bar visually occupies (status bar + app bar
    // height + its 1px bottom border) before the real content starts.
    // MathivaAppBar is 74 tall when it has a subtitle, which this screen
    // always passes.
    const appBarHeight = 74.0;
    const appBarBottomBorder = 1.0;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = statusBarHeight + appBarHeight + appBarBottomBorder + 12;

    final Widget body;
    if (_loadingQuestion) {
      body = _buildLoading(topPadding);
    } else if (_loadError != null) {
      body = _buildError(topPadding);
    } else {
      body = _buildQuestion(topPadding);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        // Difficulty is chosen adaptively by the server, so show what was
        // actually served once it's loaded (a neutral title until then).
        title: _question != null ? '${_question!.difficulty} Practice' : 'Practice',
        subtitle: 'Choose your answer carefully',
        icon: Icons.edit_note_rounded,
        onBack: () => context.canPop() ? context.pop() : context.go('/concept'),
        actions: [
          IconButton(
            tooltip: 'Ask Math Tutor',
            onPressed: () => context.push(RouteNames.chat),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            color: primary,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBackground(
        vivid: true,
        child: SafeArea(top: false, child: body),
      ),
    );
  }

  Widget _buildLoading(double topPadding) {
    final colors = AppTheme.colorsOf(context);
    final primary = AppPreferences.palette.value.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primary),
            const SizedBox(height: 18),
            Text(
              'Generating your question…',
              style:
                  TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(double topPadding) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _sessionExpired
                  ? Icons.lock_clock_rounded
                  : Icons.cloud_off_rounded,
              size: 48,
              color: colors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.ink, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: _sessionExpired
                  ? _GradientButton(
                      label: 'Log In Again',
                      onPressed: () => context.go(RouteNames.login),
                    )
                  : _GradientButton(
                      label: 'Try Again', onPressed: _loadQuestion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(double topPadding) {
    final colors = AppTheme.colorsOf(context);
    final question = _question!;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCard(
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
                question.question,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose an answer. The next screen will show the solution and why it works.',
                style: TextStyle(color: colors.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...question.choices.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceTile(
              label: choice,
              selected: _selected == choice,
              onTap: _submitting
                  ? () {}
                  : () => setState(() => _selected = choice),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _GradientButton(
          label: _submitting ? 'Checking…' : 'Submit Answer',
          onPressed: (_selected == null || _submitting) ? null : _submit,
        ),
      ],
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
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? primary : colors.border),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(selected ? .12 : .06),
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
                  color: selected ? primary : colors.glassChipFill,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? primary : colors.ink,
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
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: primary),
          const SizedBox(width: 5),
          Text(
            _formatTimer(seconds),
            style: TextStyle(color: primary, fontWeight: FontWeight.w700),
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
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: colors.glassChipFill, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
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
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    final isDisabled = onPressed == null;
    final accentColor = isDisabled ? colors.subtleMuted : primary;

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

String _formatTimer(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}
