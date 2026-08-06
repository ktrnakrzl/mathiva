import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MathiviaPalette {
  final String name;
  final Color primary;
  final Color secondary;
  final List<Color> background;

  const MathiviaPalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
  });
}

class AppPreferences {
  static const _studentNameKey = 'pref_student_name';
  static const _learnerRoleKey = 'pref_learner_role';
  static const _notificationsEnabledKey = 'pref_notifications_enabled';
  static const _studyRemindersEnabledKey = 'pref_study_reminders_enabled';
  static const _reminderHourKey = 'pref_reminder_hour';
  static const _reminderMinuteKey = 'pref_reminder_minute';
  static const _privateProfileKey = 'pref_private_profile';
  static const _saveLearningProgressKey = 'pref_save_learning_progress';
  static const _darkModeKey = 'pref_dark_mode';
  static const _hapticFeedbackKey = 'pref_haptic_feedback';
  static const _textScaleKey = 'pref_text_scale';
  static const _paletteNameKey = 'pref_palette_name';

  static bool _ready = false;

  static final ValueNotifier<bool> notificationsEnabled =
      ValueNotifier<bool>(true);
  static final ValueNotifier<bool> studyRemindersEnabled =
      ValueNotifier<bool>(false);
  static final ValueNotifier<TimeOfDay> reminderTime =
      ValueNotifier<TimeOfDay>(const TimeOfDay(hour: 19, minute: 0));

  static final ValueNotifier<String> studentName =
      ValueNotifier<String>('Learner');
  static final ValueNotifier<String> learnerRole =
      ValueNotifier<String>('Senior High School Learner');
  static final ValueNotifier<bool> privateProfile = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> saveLearningProgress =
      ValueNotifier<bool>(true);
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> hapticFeedback = ValueNotifier<bool>(true);
  static final ValueNotifier<double> textScale = ValueNotifier<double>(1.0);

  static const List<MathiviaPalette> palettes = [
    // shadcn reskin: the single violet accent is the default. (The remaining
    // palette entries below are retained for the deferred accent-picker
    // feature but are not surfaced in the shadcn Settings screen yet.)
    MathiviaPalette(
      name: 'Violet',
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF6D28D9),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Ocean Blue',
      primary: Color(0xFF1D75F0),
      secondary: Color(0xFF28C2D1),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Fresh Green',
      primary: Color(0xFF2F9E44),
      secondary: Color(0xFF82C91E),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Warm Peach',
      primary: Color(0xFFE8590C),
      secondary: Color(0xFFFF922B),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Rose Pink',
      primary: Color(0xFFD6336C),
      secondary: Color(0xFFF06595),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Midnight Teal',
      primary: Color(0xFF0B7285),
      secondary: Color(0xFF15AABF),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Slate Indigo',
      primary: Color(0xFF3B5BDB),
      secondary: Color(0xFF748FFC),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Golden Amber',
      primary: Color(0xFFF59F00),
      secondary: Color(0xFFFFD43B),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Soft Lavender',
      primary: Color(0xFF9C36B5),
      secondary: Color(0xFFCC5DE8),
      background: [Colors.white, Colors.white, Colors.white],
    ),
    MathiviaPalette(
      name: 'Earthy Brown',
      primary: Color(0xFF8B4513),
      secondary: Color(0xFFCD853F),
      background: [Colors.white, Colors.white, Colors.white],
    ),
  ];

  static final ValueNotifier<MathiviaPalette> palette =
      ValueNotifier<MathiviaPalette>(palettes.first);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    notificationsEnabled.value =
        prefs.getBool(_notificationsEnabledKey) ?? notificationsEnabled.value;
    studyRemindersEnabled.value =
        prefs.getBool(_studyRemindersEnabledKey) ?? studyRemindersEnabled.value;
    reminderTime.value = TimeOfDay(
      hour: prefs.getInt(_reminderHourKey) ?? reminderTime.value.hour,
      minute: prefs.getInt(_reminderMinuteKey) ?? reminderTime.value.minute,
    );
    studentName.value = prefs.getString(_studentNameKey) ?? studentName.value;
    learnerRole.value = prefs.getString(_learnerRoleKey) ?? learnerRole.value;
    privateProfile.value =
        prefs.getBool(_privateProfileKey) ?? privateProfile.value;
    saveLearningProgress.value =
        prefs.getBool(_saveLearningProgressKey) ?? saveLearningProgress.value;
    darkMode.value = prefs.getBool(_darkModeKey) ?? darkMode.value;
    hapticFeedback.value =
        prefs.getBool(_hapticFeedbackKey) ?? hapticFeedback.value;
    textScale.value = prefs.getDouble(_textScaleKey) ?? textScale.value;

    final paletteName = prefs.getString(_paletteNameKey);
    if (paletteName != null) {
      palette.value = palettes.firstWhere(
        (p) => p.name == paletteName,
        orElse: () => palettes.first,
      );
    }

    _ready = true;
    notificationsEnabled.addListener(
        () => _saveBool(_notificationsEnabledKey, notificationsEnabled.value));
    studyRemindersEnabled.addListener(() =>
        _saveBool(_studyRemindersEnabledKey, studyRemindersEnabled.value));
    reminderTime.addListener(_saveReminderTime);
    studentName
        .addListener(() => _saveString(_studentNameKey, studentName.value));
    learnerRole
        .addListener(() => _saveString(_learnerRoleKey, learnerRole.value));
    privateProfile
        .addListener(() => _saveBool(_privateProfileKey, privateProfile.value));
    saveLearningProgress.addListener(
        () => _saveBool(_saveLearningProgressKey, saveLearningProgress.value));
    darkMode.addListener(() => _saveBool(_darkModeKey, darkMode.value));
    hapticFeedback
        .addListener(() => _saveBool(_hapticFeedbackKey, hapticFeedback.value));
    textScale.addListener(() => _saveDouble(_textScaleKey, textScale.value));
    palette.addListener(() => _saveString(_paletteNameKey, palette.value.name));
  }

  static Future<void> _saveBool(String key, bool value) async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<void> _saveDouble(String key, double value) async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  static Future<void> _saveString(String key, String value) async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> _saveReminderTime() async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, reminderTime.value.hour);
    await prefs.setInt(_reminderMinuteKey, reminderTime.value.minute);
  }

  static void setPalette(MathiviaPalette value) {
    palette.value = value;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }
}
