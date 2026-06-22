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

  static const List<MathiviaPalette> palettes = [
    MathiviaPalette(
      name: 'Pastel Purple',
      primary: Color(0xFF7A3CFF),
      secondary: Color(0xFFB35CFF),
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

  static final ValueNotifier<MathiviaPalette> palette = ValueNotifier<MathiviaPalette>(palettes.first);

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
