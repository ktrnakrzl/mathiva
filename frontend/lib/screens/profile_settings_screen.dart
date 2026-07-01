import 'package:flutter/material.dart';
import '../presentation/widgets/animated_background.dart';
import 'package:go_router/go_router.dart';

import '../presentation/widgets/glass_card.dart';
import '../services/app_preferences.dart';
import '../services/notification_service.dart';
import '../services/progress_service.dart';
import '../services/progress_store.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  void initState() {
    super.initState();
    ProgressStore.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        final primary = palette.primary;
        final secondary = palette.secondary;
        final colors = AppTheme.colorsOf(context);

        return Scaffold(
          backgroundColor: colors.pageBg,
          extendBody: true,
          appBar: const MathivaTopBar(),
          body: AnimatedBackground(
            vivid: true,
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 112),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Page title (lives in the body, not the top bar).
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ),

                  // ── Avatar card ──────────────────────────────────────────
                  _LearningAccountCard(primary: primary),

                  const SizedBox(height: 20),

                  // ── Stat row ─────────────────────────────────────────────
                  // Same three aggregates as the Progress tab, sourced from
                  // real attempt history. Zeros until the first fetch resolves.
                  ValueListenableBuilder<UserProgress?>(
                    valueListenable: ProgressStore.current,
                    builder: (context, progress, _) {
                      return Row(
                        children: [
                          Expanded(
                              child: _Stat(
                                  value: '${progress?.totalAttempts ?? 0}',
                                  label: 'Solved',
                                  primary: primary)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _Stat(
                                  value:
                                      '${(progress?.overallAccuracy ?? 0).round()}%',
                                  label: 'Accuracy',
                                  primary: primary)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _Stat(
                                  value: '${progress?.currentStreakDays ?? 0}',
                                  label: 'Streak',
                                  primary: primary)),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Preferences ──────────────────────────────────────────
                  const _SectionTitle('Preferences'),
                  const SizedBox(height: 10),

                  // Dark Mode lives in the top-bar toggle now, not here.
                  ValueListenableBuilder<bool>(
                    valueListenable: AppPreferences.notificationsEnabled,
                    builder: (context, enabled, _) => _SwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Quiz reminders and progress updates',
                      value: enabled,
                      onChanged: (v) => _onNotificationsChanged(context, v),
                      primary: primary,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: AppPreferences.studyRemindersEnabled,
                    builder: (context, enabled, _) => _SwitchTile(
                      icon: Icons.alarm_outlined,
                      title: 'Study Reminders',
                      subtitle: 'Daily reminder to keep your streak alive',
                      value: enabled,
                      onChanged: (v) => _onStudyRemindersChanged(context, v),
                      primary: primary,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: AppPreferences.hapticFeedback,
                    builder: (context, enabled, _) => _SwitchTile(
                      icon: Icons.vibration_outlined,
                      title: 'Haptic Feedback',
                      subtitle: 'Feel a vibration on correct answers',
                      value: enabled,
                      onChanged: (v) => AppPreferences.hapticFeedback.value = v,
                      primary: primary,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: AppPreferences.saveLearningProgress,
                    builder: (context, enabled, _) => _SwitchTile(
                      icon: Icons.save_alt_outlined,
                      title: 'Save Progress',
                      subtitle: 'Store learning progress on this device',
                      value: enabled,
                      onChanged: (v) =>
                          AppPreferences.saveLearningProgress.value = v,
                      primary: primary,
                    ),
                  ),

                  const SizedBox(height: 8),
                  const _SectionTitle('General'),
                  const SizedBox(height: 10),

                  _Tile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Mathivia',
                    subtitle: 'Learn more about this app',
                    primary: primary,
                    onTap: () => _showAbout(context, primary, secondary),
                  ),

                  const SizedBox(height: 24),
                  _LogOutButton(onPressed: () => context.go(RouteNames.login)),
                ],
              ),
            ),
          ),
          bottomNavigationBar:
              const MathivaBottomNav(selected: MathivaTab.settings),
        );
      },
    );
  }

  // ─── Notifications toggle ───────────────────────────────────────────────────
  static Future<void> _onNotificationsChanged(
      BuildContext context, bool value) async {
    if (!value) {
      AppPreferences.notificationsEnabled.value = false;
      await NotificationService.instance.cancelDailyStreakReminder();
      return;
    }

    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Notification permission was denied. Enable it in your device settings to receive reminders.'),
          ),
        );
      }
      return;
    }

    AppPreferences.notificationsEnabled.value = true;
    if (AppPreferences.studyRemindersEnabled.value) {
      await NotificationService.instance.scheduleDailyStreakReminder(
        AppPreferences.reminderTime.value,
      );
    }
  }

  // ─── Study Reminders toggle ─────────────────────────────────────────────────
  static Future<void> _onStudyRemindersChanged(
      BuildContext context, bool value) async {
    AppPreferences.studyRemindersEnabled.value = value;

    if (!value) {
      await NotificationService.instance.cancelDailyStreakReminder();
      return;
    }

    if (!AppPreferences.notificationsEnabled.value) {
      // Master switch is off — save the preference, but don't schedule
      // anything or prompt for permission until Notifications is also on.
      return;
    }

    await NotificationService.instance.scheduleDailyStreakReminder(
      AppPreferences.reminderTime.value,
    );
  }

  // ─── About sheet ──────────────────────────────────────────────────────────────
  static void _showAbout(BuildContext context, Color primary, Color secondary) {
    final colors = AppTheme.colorsOf(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scroll,
            children: [
              Row(children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(99)),
                ),
                const Spacer(),
                IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.muted),
                    onPressed: () => sheetCtx.pop()),
              ]),
              // App icon — tinted primary fill, matches HomeScreen icon-tile motif
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withOpacity(0.15)),
                  ),
                  child: Center(
                    child: Text('m',
                        style: TextStyle(
                            color: primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                  child: Text('Mathivia',
                      style: TextStyle(
                          color: colors.ink,
                          fontSize: 26,
                          fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Center(
                  child: Text('Version 1.0.0',
                      style: TextStyle(color: colors.subtleMuted, fontSize: 13))),
              const SizedBox(height: 24),
              _AboutSection(
                title: 'What is Mathivia?',
                icon: Icons.auto_awesome_outlined,
                primary: primary,
                body:
                    'Mathivia is a thoughtfully designed math learning companion built specifically for Senior High School students following the K–12 curriculum. It combines the power of AI tutoring with structured lesson content, interactive quizzes, and detailed step-by-step problem explanations — all wrapped in a clean, distraction-free interface.\n\nWhether you are a Grade 11 student tackling General Mathematics and Statistics for the first time, or a Grade 12 learner deepening your understanding of Pre-Calculus and Basic Calculus, Mathivia has the content and tools to guide you every step of the way.',
              ),
              const SizedBox(height: 12),
              _AboutSection(
                title: 'Subjects Covered',
                icon: Icons.menu_book_outlined,
                primary: primary,
                body:
                    'Mathivia currently covers four core math subjects from the Philippine SHS curriculum:\n\n• General Mathematics (Grade 11) — functions, rational expressions, inverse functions, exponential and logarithmic functions, simple and compound interest, annuities, stocks and bonds, and logic.\n\n• Statistics and Probability (Grade 11) — data collection, measures of central tendency, measures of spread, normal distribution, hypothesis testing, and basic probability theory.\n\n• Pre-Calculus (Grade 12) — analytic geometry, conic sections (circles, parabolas, ellipses, hyperbolas), series and sequences, trigonometric identities, polar coordinates, and parametric equations.\n\n• Basic Calculus (Grade 12) — limits and continuity, derivatives and differentiation rules, applications of derivatives, antiderivatives, definite integrals, and the fundamental theorem of calculus.',
              ),
              const SizedBox(height: 12),
              _AboutSection(
                title: 'Key Features',
                icon: Icons.star_outline_rounded,
                primary: primary,
                body:
                    '📷  Scan & Solve — point your camera at any printed or handwritten math problem and Mathivia\'s AI will recognize it, break it down step by step, and explain the solution clearly.\n\n📚  Structured Lessons — every topic is broken into bite-sized lessons with definitions, formulas, worked examples, and practice problems arranged in a logical learning order.\n\n🧠  AI Math Tutor — chat with the built-in tutor to ask any math question, request alternative explanations, or explore deeper connections between concepts.\n\n📊  Progress Tracking — track mastery per topic and subject, see your accuracy over time, and earn badges for consistent practice.\n\n🎯  Practice Mode — generate unlimited practice problems across any subject or topic and receive immediate, detailed feedback with every answer.',
              ),
              const SizedBox(height: 12),
              _AboutSection(
                title: 'Our Philosophy',
                icon: Icons.lightbulb_outline_rounded,
                primary: primary,
                body:
                    'Mathivia was built on a simple belief: every student deserves to understand math, not just memorize it. Too many students struggle not because they lack ability, but because they lack access to patient, clear, and personalized explanations.\n\nWe designed Mathivia to be the math tutor that is always available — one that never gets tired of explaining the same concept a different way, never makes you feel embarrassed for asking a basic question, and always celebrates your progress no matter how small.\n\nThe interface is intentionally minimal. No loud animations, no gamification gimmicks, no unnecessary clutter. Just clean, focused tools that put math front and center.',
              ),
              const SizedBox(height: 12),
              _AboutSection(
                title: 'Built For You',
                icon: Icons.favorite_outline_rounded,
                primary: primary,
                body:
                    'Mathivia is designed and maintained with Senior High School students in the Philippines in mind. We understand the pressure of board exams, quarterly assessments, and performance tasks — and we want to be a reliable tool you can turn to when the textbook isn\'t enough.\n\nFeedback from real students shapes every update. If there is a topic you wish was covered more deeply, a feature you think would help you learn better, or a bug that got in your way, we want to hear about it. Mathivia grows with you.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.pageBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Text('Made with ❤️ for math students',
                        style: TextStyle(
                            color: colors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text('© 2026 Mathivia. All rights reserved.',
                        style: TextStyle(color: colors.subtleMuted, fontSize: 12),
                        textAlign: TextAlign.center),
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

// ─── About section block ──────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color primary;

  const _AboutSection(
      {required this.title,
      required this.body,
      required this.icon,
      required this.primary});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: TextStyle(
                  color: colors.muted, fontSize: 13.5, height: 1.55)),
        ],
      ),
    );
  }
}

// ─── Avatar / account card ────────────────────────────────────────────────────
class _LearningAccountCard extends StatelessWidget {
  final Color primary;
  const _LearningAccountCard({required this.primary});

  void _showEditName(BuildContext context) {
    final controller =
        TextEditingController(text: AppPreferences.studentName.value);
    final colors = AppTheme.colorsOf(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Row(children: [
                Expanded(
                    child: Text('Edit Name',
                        style: TextStyle(
                            color: colors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700))),
                IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.muted),
                    onPressed: () => sheetCtx.pop()),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                    color: colors.ink, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  filled: true,
                  fillColor: colors.pageBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary, width: 1.5)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty)
                      AppPreferences.studentName.value = name;
                    sheetCtx.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: primary,
                    side: BorderSide(color: primary, width: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Save',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return ValueListenableBuilder<String>(
      valueListenable: AppPreferences.studentName,
      builder: (ctx, name, _) {
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';
        return _Card(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar — tinted primary circle, matches icon-tile motif
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: primary.withOpacity(0.18)),
                ),
                child: Center(
                  child: Text(initial,
                      style: TextStyle(
                          color: primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : 'Learner',
                        style: TextStyle(
                            color: colors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('Senior High School Learner',
                        style: TextStyle(color: colors.muted, fontSize: 13)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showEditName(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_outlined, color: primary, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(title,
            style: TextStyle(
                color: AppTheme.colorsOf(context).ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      );
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color primary;
  const _Stat(
      {required this.value, required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: primary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.colorsOf(context).subtleMuted,
                  fontSize: 11.5)),
        ],
      ),
    );
  }
}

// ─── Toggle tile ──────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color primary;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _Tile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      primary: primary,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primary,
        inactiveThumbColor: colors.subtleMuted,
        inactiveTrackColor: colors.border,
      ),
    );
  }
}

// ─── List tile ────────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Card(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        onTap: onTap,
        child: Row(
          children: [
            // Icon container — tinted primary fill, matches Home/Search/Login motif
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(color: colors.subtleMuted, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: colors.subtleMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Log out button ───────────────────────────────────────────────────────────
class _LogOutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _LogOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.muted,
          side: BorderSide(color: colors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.muted)),
      ),
    );
  }
}

// ─── Shared white card ────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const _Card(
      {required this.child,
      this.padding = const EdgeInsets.all(16),
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: child,
    );
  }
}
