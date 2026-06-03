import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/app_preferences.dart';
import '../widgets/mathiva_bottom_nav.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> with SingleTickerProviderStateMixin {
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

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: AppPreferences.reminderTime.value);
    if (picked != null) {
      AppPreferences.reminderTime.value = picked;
      AppPreferences.studyRemindersEnabled.value = true;
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Study reminder set for ${picked.format(context)}.')));
      }
    }
  }

  Future<void> _showAppearanceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return ValueListenableBuilder<MathiviaPalette>(
          valueListenable: AppPreferences.palette,
          builder: (context, active, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose palette', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  const Text('This now changes Mathivia colors across screens, buttons, progress bars, and the bottom navigation.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 18),
                  for (final palette in AppPreferences.palettes) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [palette.primary, palette.secondary]),
                        ),
                      ),
                      title: Text(palette.name, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                      trailing: active == palette ? Icon(Icons.check_circle_rounded, color: palette.primary) : const Icon(Icons.circle_outlined, color: AppColors.muted),
                      onTap: () {
                        AppPreferences.setPalette(palette);
                        setState(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Palette changed to ${palette.name}.')));
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPrivacyAccountSheet() async {
    final nameController = TextEditingController(text: AppPreferences.studentName.value);
    final roleController = TextEditingController(text: AppPreferences.learnerRole.value);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(22, 6, 22, MediaQuery.of(context).viewInsets.bottom + 28),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Privacy and account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    const Text('Edit the student profile and choose what Mathivia saves locally.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student name')),
                    const SizedBox(height: 10),
                    TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Account type / grade')),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Private profile', style: TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: const Text('Keep learner details visible only on this device.'),
                      value: AppPreferences.privateProfile.value,
                      onChanged: (value) {
                        AppPreferences.privateProfile.value = value;
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Save learning progress', style: TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: const Text('Use progress data for home goals and analytics.'),
                      value: AppPreferences.saveLearningProgress.value,
                      onChanged: (value) {
                        AppPreferences.saveLearningProgress.value = value;
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save account settings'),
                        onPressed: () {
                          AppPreferences.studentName.value = nameController.text.trim().isEmpty ? 'Learner' : nameController.text.trim();
                          AppPreferences.learnerRole.value = roleController.text.trim().isEmpty ? 'Senior High School Learner' : roleController.text.trim();
                          setState(() {});
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account and privacy settings saved.')));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    final palette = AppPreferences.palette.value;
    showAboutDialog(
      context: context,
      applicationName: 'Mathivia',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [palette.secondary, palette.primary]),
        ),
        child: const Center(child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30))),
      ),
      children: const [
        SizedBox(height: 8),
        Text(
          'Mathivia is a student-friendly mathematics learning app created to help learners study, practice, and track progress in one simple place. It is designed for topics such as General Mathematics, Statistics and Probability, Pre-Calculus, and Basic Calculus, with lessons that explain concepts step by step and practice questions that help students check their understanding.',
        ),
        SizedBox(height: 12),
        Text(
          'The app focuses on making math less intimidating. Instead of forcing students to type long answers on a keypad, Mathivia uses multiple-choice practice so learners can concentrate on choosing the best solution, comparing options, and learning from mistakes. Practice sessions also include a timer that counts upward, so students can see how long they spent solving without feeling pressured by a countdown.',
        ),
        SizedBox(height: 12),
        Text(
          'Mathivia also includes progress tracking, study reminders, notification controls, account and privacy settings, and palette customization. The progress page helps students see completed lessons, subject progress, and weekly activity. The settings page lets learners personalize their study experience, choose app colors, manage reminders, and keep learner information private on the device.',
        ),
        SizedBox(height: 12),
        Text(
          'The goal of Mathivia is to support independent learning: read a concept, practice it, review progress, and return to topics that need improvement. It is built as a practical math companion for students who want a cleaner, easier, and more motivating way to study mathematics.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathiviaPalette>(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
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
                Positioned(top: -75, left: -65, child: _GlowBlob(size: 190, color: palette.secondary.withOpacity(.38))),
                Positioned(top: 170, right: -90, child: _GlowBlob(size: 230, color: palette.primary.withOpacity(.28))),
                Positioned(bottom: 10, left: -90, child: _GlowBlob(size: 240, color: palette.secondary.withOpacity(.22))),
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 148),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _AnimatedIn(animation: _controller, intervalStart: 0, child: const _Header()),
                      const SizedBox(height: 22),
                      _AnimatedIn(animation: _controller, intervalStart: .12, child: const _ProfileCard()),
                      const SizedBox(height: 22),
                      _AnimatedIn(
                        animation: _controller,
                        intervalStart: .20,
                        child: const Text('Settings', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: AppPreferences.notificationsEnabled,
                        builder: (context, value, _) {
                          return _AnimatedIn(
                            animation: _controller,
                            intervalStart: .28,
                            child: _SettingsTile(
                              icon: Icons.notifications_rounded,
                              title: 'Notifications',
                              subtitle: value ? 'On - app updates and practice alerts allowed' : 'Off - alerts are muted',
                              trailing: Switch(
                                value: value,
                                onChanged: (newValue) {
                                  AppPreferences.notificationsEnabled.value = newValue;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newValue ? 'Notifications turned on.' : 'Notifications turned off.')));
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: AppPreferences.studyRemindersEnabled,
                        builder: (context, enabled, _) {
                          return ValueListenableBuilder<TimeOfDay>(
                            valueListenable: AppPreferences.reminderTime,
                            builder: (context, time, _) {
                              return _AnimatedIn(
                                animation: _controller,
                                intervalStart: .36,
                                child: _SettingsTile(
                                  icon: Icons.alarm_rounded,
                                  title: 'Study reminders',
                                  subtitle: enabled ? 'Daily reminder at ${time.format(context)}' : 'Off - tap clock to choose a time',
                                  onTap: _pickReminderTime,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(onPressed: _pickReminderTime, icon: Icon(Icons.schedule_rounded, color: palette.primary)),
                                      Switch(
                                        value: enabled,
                                        onChanged: (value) async {
                                          AppPreferences.studyRemindersEnabled.value = value;
                                          if (value) await _pickReminderTime();
                                          if (mounted && !value) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Study reminders turned off.')));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _AnimatedIn(
                        animation: _controller,
                        intervalStart: .44,
                        child: _SettingsTile(
                          icon: Icons.palette_rounded,
                          title: 'Appearance',
                          subtitle: palette.name,
                          onTap: _showAppearanceSheet,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [palette.primary, palette.secondary]),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.ink.withOpacity(.15), width: 2),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: palette.primary, size: 30),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: AppPreferences.privateProfile,
                        builder: (context, private, _) {
                          return _AnimatedIn(
                            animation: _controller,
                            intervalStart: .52,
                            child: _SettingsTile(
                              icon: Icons.lock_rounded,
                              title: 'Privacy and account',
                              subtitle: private ? 'Private profile and local progress controls' : 'Profile visibility is less restricted',
                              onTap: _showPrivacyAccountSheet,
                              trailing: Icon(Icons.chevron_right_rounded, color: palette.primary, size: 30),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _AnimatedIn(
                        animation: _controller,
                        intervalStart: .60,
                        child: _SettingsTile(
                          icon: Icons.info_rounded,
                          title: 'About Mathivia',
                          subtitle: 'App information, version, and features',
                          onTap: _showAboutDialog,
                          trailing: Icon(Icons.chevron_right_rounded, color: palette.primary, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const MathivaBottomNav(selected: MathivaTab.profile),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Settings', style: TextStyle(fontSize: 30, height: 1.05, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -.5)),
        SizedBox(height: 8),
        Text('Manage your account and study preferences.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.muted)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    return _GlassCard(
      child: Row(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: AppPreferences.studentName,
            builder: (context, name, _) {
              final initial = name.trim().isEmpty ? 'S' : name.trim().substring(0, 1).toUpperCase();
              return Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [palette.secondary, palette.primary]),
                ),
                alignment: Alignment.center,
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: AppPreferences.studentName,
                  builder: (context, name, _) => Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.ink)),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<String>(
                  valueListenable: AppPreferences.learnerRole,
                  builder: (context, role, _) => Text(role, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPreferences.palette.value;
    final content = Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: palette.primary.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: palette.primary, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 15)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );

    return _GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: content),
        ),
      ),
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
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(.95)),
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
    final curved = CurvedAnimation(parent: animation, curve: Interval(math.max(0.0, math.min(intervalStart, .92)), 1, curve: Curves.easeOutCubic));

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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
