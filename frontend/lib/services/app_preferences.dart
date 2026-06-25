import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> studyRemindersEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<TimeOfDay> reminderTime = ValueNotifier<TimeOfDay>(const TimeOfDay(hour: 19, minute: 0));

  static final ValueNotifier<String> studentName = ValueNotifier<String>('Learner');
  static final ValueNotifier<String> learnerRole = ValueNotifier<String>('Senior High School Learner');
  static final ValueNotifier<bool> privateProfile = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> saveLearningProgress = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> hapticFeedback = ValueNotifier<bool>(true);
  static final ValueNotifier<double> textScale = ValueNotifier<double>(1.0);

  // Each palette provides three background stop colors used by AtmosphereBackground
  // and AnimatedBackground. The stops are tuned so that even the most vivid palettes
  // (Golden Amber, Rose Pink) stay light enough to keep white-card surfaces readable.
  static const List<MathiviaPalette> palettes = [
    MathiviaPalette(
      name: 'Pastel Purple',
      primary: Color(0xFF7A3CFF),
      secondary: Color(0xFFB35CFF),
      background: [Color(0xFFFBF9FF), Color(0xFFF3ECFF), Color(0xFFFFFDFF)],
    ),
    MathiviaPalette(
      name: 'Ocean Blue',
      primary: Color(0xFF1D75F0),
      secondary: Color(0xFF28C2D1),
      background: [Color(0xFFF5FAFF), Color(0xFFEBF4FF), Color(0xFFF8FDFF)],
    ),
    MathiviaPalette(
      name: 'Fresh Green',
      primary: Color(0xFF2F9E44),
      secondary: Color(0xFF82C91E),
      background: [Color(0xFFF4FBF5), Color(0xFFEAF6EC), Color(0xFFF7FCF8)],
    ),
    MathiviaPalette(
      name: 'Warm Peach',
      primary: Color(0xFFE8590C),
      secondary: Color(0xFFFF922B),
      background: [Color(0xFFFFF8F4), Color(0xFFFFF0E6), Color(0xFFFFFBF8)],
    ),
    MathiviaPalette(
      name: 'Rose Pink',
      primary: Color(0xFFD6336C),
      secondary: Color(0xFFF06595),
      background: [Color(0xFFFFF5F8), Color(0xFFFFEBF2), Color(0xFFFFF8FB)],
    ),
    MathiviaPalette(
      name: 'Midnight Teal',
      primary: Color(0xFF0B7285),
      secondary: Color(0xFF15AABF),
      background: [Color(0xFFF3FBFC), Color(0xFFE5F6F8), Color(0xFFF6FCFD)],
    ),
    MathiviaPalette(
      name: 'Slate Indigo',
      primary: Color(0xFF3B5BDB),
      secondary: Color(0xFF748FFC),
      background: [Color(0xFFF5F7FF), Color(0xFFEBEFFF), Color(0xFFF8F9FF)],
    ),
    MathiviaPalette(
      name: 'Golden Amber',
      primary: Color(0xFFF59F00),
      secondary: Color(0xFFFFD43B),
      background: [Color(0xFFFFFBF0), Color(0xFFFFF5D6), Color(0xFFFFFDF5)],
    ),
    MathiviaPalette(
      name: 'Soft Lavender',
      primary: Color(0xFF9C36B5),
      secondary: Color(0xFFCC5DE8),
      background: [Color(0xFFFCF5FF), Color(0xFFF7E9FF), Color(0xFFFEF8FF)],
    ),
    MathiviaPalette(
      name: 'Earthy Brown',
      primary: Color(0xFF8B4513),
      secondary: Color(0xFFCD853F),
      background: [Color(0xFFFBF7F4), Color(0xFFF5EDE5), Color(0xFFFDF9F7)],
    ),
  ];

  static final ValueNotifier<MathiviaPalette> palette = ValueNotifier<MathiviaPalette>(palettes.first);

  static void setPalette(MathiviaPalette value) {
    palette.value = value;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Navigation bar mirrors the scaffold background so the system UI
      // feels like a continuous surface when the user switches palettes.
      systemNavigationBarColor: value.background.last,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }
}