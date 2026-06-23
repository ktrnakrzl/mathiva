import 'package:flutter/material.dart';
import 'services/app_preferences.dart';
import 'services/notification_service.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppPreferences.palette.value.background.last,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await NotificationService.instance.init();
  runApp(const MathivaApp());
}
