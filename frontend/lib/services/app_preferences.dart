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

  static const List<MathiviaPalette> palettes = [
    MathiviaPalette(
      name: 'Pastel Purple',
      primary: Color(0xFF7A3CFF),
      secondary: Color(0xFFB35CFF),
      background: [Color(0xFFFFF1FA), Color(0xFFF7F0FF), Color(0xFFEEF8FF)],
    ),
    MathiviaPalette(
      name: 'Ocean Blue',
      primary: Color(0xFF1D75F0),
      secondary: Color(0xFF28C2D1),
      background: [Color(0xFFEAF6FF), Color(0xFFEFFBFF), Color(0xFFF7FDFF)],
    ),
    MathiviaPalette(
      name: 'Fresh Green',
      primary: Color(0xFF2F9E44),
      secondary: Color(0xFF82C91E),
      background: [Color(0xFFF0FFF4), Color(0xFFF4FFF8), Color(0xFFEFFFF6)],
    ),
    MathiviaPalette(
      name: 'Warm Peach',
      primary: Color(0xFFE8590C),
      secondary: Color(0xFFFF922B),
      background: [Color(0xFFFFF4E6), Color(0xFFFFF8F0), Color(0xFFFFFBF5)],
    ),
  ];

  static final ValueNotifier<MathiviaPalette> palette = ValueNotifier<MathiviaPalette>(palettes.first);

  static void setPalette(MathiviaPalette value) {
    palette.value = value;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: value.background.last,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }
}
