import 'package:flutter/material.dart';

import 'screens/concept_progress_screen.dart';
import 'screens/concept_reading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/image_solver_screen.dart';
import 'screens/lesson_detail_screen.dart';
import 'screens/lesson_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/math_subjects_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/progress_overview_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/register_screen.dart';
import 'screens/result_screen.dart';
import 'screens/search_screen.dart';
import 'screens/solution_screen.dart';
import 'screens/subject_progress_screen.dart';
import 'screens/topic_analytics_screen.dart';
import 'theme/app_theme.dart';
import 'services/app_preferences.dart';
import 'utils/route_names.dart';

class MathivaApp extends StatelessWidget {
  const MathivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppPreferences.palette,
      builder: (context, palette, _) {
        return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mathivia',
      theme: AppTheme.light(palette),
      initialRoute: RouteNames.login,
      routes: {
        RouteNames.login: (_) => const LoginScreen(),
        RouteNames.register: (_) => const RegisterScreen(),
        RouteNames.home: (_) => const HomeScreen(),
        RouteNames.search: (_) => const SearchScreen(),
        RouteNames.subjects: (_) => const MathSubjectsScreen(),
        RouteNames.imageSolver: (_) => const ImageSolverScreen(),
        RouteNames.progress: (_) => const ProgressOverviewScreen(),
        RouteNames.profile: (_) => const ProfileSettingsScreen(),
      },
      onGenerateRoute: (settings) {
        final args = (settings.arguments as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
        switch (settings.name) {
          case RouteNames.lessons:
            return MaterialPageRoute(builder: (_) => LessonListScreen(subjectId: args['subjectId']!));
          case RouteNames.lessonDetail:
            return MaterialPageRoute(builder: (_) => LessonDetailScreen(subjectId: args['subjectId']!, topicId: args['topicId']!, lessonId: args['lessonId']!));
          case RouteNames.concept:
            return MaterialPageRoute(builder: (_) => ConceptReadingScreen(subjectId: args['subjectId']!, topicId: args['topicId']!, lessonId: args['lessonId']!, conceptId: args['conceptId']!));
          case RouteNames.practice:
            return MaterialPageRoute(builder: (_) => PracticeScreen(subjectId: args['subjectId']!, topicId: args['topicId']!, lessonId: args['lessonId']!, conceptId: args['conceptId']!, difficulty: args['difficulty'] ?? 'Easy'));
          case RouteNames.result:
            return MaterialPageRoute(builder: (_) => ResultScreen(subjectId: args['subjectId']!, topicId: args['topicId']!, lessonId: args['lessonId']!, conceptId: args['conceptId']!, difficulty: args['difficulty'] ?? 'Easy', selectedAnswer: args['selectedAnswer'] as String?, elapsedSeconds: args['elapsedSeconds'] as int?, isCorrect: args['isCorrect'] as bool?));
          case RouteNames.conceptProgress:
            return MaterialPageRoute(builder: (_) => ConceptProgressScreen(subjectId: args['subjectId']!, topicId: args['topicId']!, lessonId: args['lessonId']!));
          case RouteNames.solution:
            return MaterialPageRoute(builder: (_) => const SolutionScreen());
          case RouteNames.subjectProgress:
            return MaterialPageRoute(builder: (_) => SubjectProgressScreen(subjectId: args['subjectId']!));
          case RouteNames.topicAnalytics:
            return MaterialPageRoute(builder: (_) => TopicAnalyticsScreen(subjectId: args['subjectId']!, topicId: args['topicId']!));
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      },
        );
      },
    );
  }
}
