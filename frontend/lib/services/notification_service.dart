import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_timezone/timezone_info.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'app_preferences.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _streakReminderId = 1001;
  static const String _channelId = 'study_reminders';
  static const String _channelName = 'Study Reminders';
  static const String _channelDescription =
      'Daily reminders to keep your Mathivia streak alive.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Sets up the plugin and timezone database. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
      final String ianaName = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(ianaName));
    } catch (_) {
      // Fallback if the platform's timezone identifier can't be resolved.
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;

    // If the user already has both switches on from a previous session,
    // re-arm the reminder (e.g. after the OS killed and relaunched the app).
    if (AppPreferences.notificationsEnabled.value &&
        AppPreferences.studyRemindersEnabled.value) {
      await scheduleDailyStreakReminder(AppPreferences.reminderTime.value);
    }
  }

  /// Asks the user for OS-level notification permission.
  /// Returns true if permission is granted (or not required on this OS).
  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      // Android < 13 has no runtime permission and reports null; treat
      // that as granted since the app can already post notifications.
      return granted ?? true;
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Schedules (or re-schedules) the daily streak reminder for [time].
  Future<void> scheduleDailyStreakReminder(TimeOfDay time) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id: _streakReminderId,
      title: "Don't lose your streak!",
      body: 'Solve a quick problem in Mathivia to keep today\'s streak going.',
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels the daily streak reminder.
  Future<void> cancelDailyStreakReminder() async {
    await init();
    await _plugin.cancel(id: _streakReminderId);
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
