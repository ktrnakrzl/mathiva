import 'package:flutter/material.dart';
import 'services/notification_service.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'repositories/mock/mock_progress_repository.dart';
import 'repositories/mock/mock_solver_repository.dart';
import 'repositories/mock/mock_tutor_repository.dart';
import 'services/chat_service.dart';
import 'services/progress_service.dart';
import 'services/solver_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // System UI overlay style (status/nav bar icon brightness) is set
  // reactively in app.dart based on AppPreferences.darkMode instead of here,
  // since it needs to flip whenever the user toggles dark mode.
  await NotificationService.instance.init();

  // Dev/demo escape hatch: route the tutor and solver facades to mock data
  // instead of the real backend when kUseMockBackend is flipped on.
  if (kUseMockBackend) {
    ChatService.repository = MockTutorRepository();
    SolverService.repository = MockSolverRepository();
    ProgressService.repository = MockProgressRepository();
  }

  runApp(const MathivaApp());
}
