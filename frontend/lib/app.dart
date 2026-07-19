import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/mathiva_models.dart';
import 'presentation/screens/progress/mastery_heatmap_screen.dart';
import 'presentation/screens/progress/rewards_screen.dart';
import 'presentation/screens/tutor/tutor_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/concept_progress_screen.dart';
import 'screens/concept_reading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/image_solver_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/lesson_detail_screen.dart';
import 'screens/lesson_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/math_subjects_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/progress_overview_screen.dart';
import 'screens/register_screen.dart';
import 'screens/result_screen.dart';
import 'screens/search_screen.dart';
import 'screens/solution_screen.dart';
import 'screens/subject_progress_screen.dart';
import 'screens/topic_analytics_screen.dart';
import 'services/app_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/semantic_colors.dart';
import 'utils/route_names.dart';

class MathivaApp extends StatelessWidget {
  const MathivaApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: RouteNames.onboarding,
    routes: [
      GoRoute(
          path: RouteNames.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: RouteNames.register,
          builder: (_, __) => const RegisterScreen()),
      GoRoute(path: RouteNames.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: RouteNames.search, builder: (_, __) => const SearchScreen()),
      GoRoute(
          path: RouteNames.subjects,
          builder: (_, __) => const MathSubjectsScreen()),
      GoRoute(
          path: RouteNames.learn, builder: (_, __) => const LearnScreen()),
      GoRoute(
          path: RouteNames.imageSolver,
          builder: (_, __) => const ImageSolverScreen()),
      GoRoute(
          path: RouteNames.progress,
          builder: (_, state) => ProgressOverviewScreen(
              scrollToAchievements: state.extra == true)),
      GoRoute(
          path: RouteNames.profile,
          builder: (_, __) => const ProfileSettingsScreen()),
      GoRoute(path: RouteNames.chat, builder: (_, __) => const ChatScreen()),
      GoRoute(
          path: RouteNames.solution,
          builder: (_, state) =>
              SolutionScreen(problem: state.extra as PracticeProblem?)),
      GoRoute(
          path: '/mastery', builder: (_, __) => const MasteryHeatmapScreen()),
      GoRoute(path: '/rewards', builder: (_, __) => const RewardsScreen()),
      GoRoute(path: '/tutor', builder: (_, __) => const TutorScreen()),
      GoRoute(
        path: RouteNames.lessons,
        builder: (_, state) {
          final args = _args(state);
          return LessonListScreen(subjectId: args['subjectId'] as String);
        },
      ),
      GoRoute(
        path: RouteNames.lessonDetail,
        builder: (_, state) {
          final args = _args(state);
          return LessonDetailScreen(
            subjectId: args['subjectId'] as String,
            topicId: args['topicId'] as String,
            lessonId: args['lessonId'] as String,
          );
        },
      ),
      GoRoute(
        path: RouteNames.concept,
        builder: (_, state) {
          final args = _args(state);
          return ConceptReadingScreen(
            subjectId: args['subjectId'] as String,
            topicId: args['topicId'] as String,
            lessonId: args['lessonId'] as String,
            conceptId: args['conceptId'] as String,
          );
        },
      ),
      GoRoute(
        path: RouteNames.practice,
        builder: (_, state) {
          final args = _args(state);
          return PracticeScreen(
            subjectId: args['subjectId'] as String,
            topicId: args['topicId'] as String,
            lessonId: args['lessonId'] as String,
            conceptId: args['conceptId'] as String,
            difficulty: args['difficulty'] as String? ?? 'Easy',
            candidateConcepts: (args['candidateConcepts'] as List?)
                ?.map((e) => e as String)
                .toList(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.result,
        builder: (_, state) {
          final args = _args(state);
          return ResultScreen(
            subjectId: args['subjectId'] as String,
            topicId: args['topicId'] as String,
            lessonId: args['lessonId'] as String,
            conceptId: args['conceptId'] as String,
            difficulty: args['difficulty'] as String? ?? 'Easy',
            selectedAnswer: args['selectedAnswer'] as String?,
            elapsedSeconds: args['elapsedSeconds'] as int?,
            isCorrect: args['isCorrect'] as bool?,
            correctAnswer: args['correctAnswer'] as String?,
            steps: (args['steps'] as List?)?.cast<String>(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.conceptProgress,
        builder: (_, state) {
          final args = _args(state);
          return ConceptProgressScreen(
            subjectId: args['subjectId'] as String,
            topicId: args['topicId'] as String,
            lessonId: args['lessonId'] as String,
            conceptId: args['conceptId'] as String?,
          );
        },
      ),
      GoRoute(
        path: RouteNames.subjectProgress,
        builder: (_, state) {
          final args = _args(state);
          return SubjectProgressScreen(subjectId: args['subjectId'] as String);
        },
      ),
      GoRoute(
        path: RouteNames.topicAnalytics,
        builder: (_, state) {
          final args = _args(state);
          return TopicAnalyticsScreen(
            subjectId: args['subjectId'] as String,
            topicId: args['topicId'] as String,
          );
        },
      ),
    ],
    errorBuilder: (_, __) => const LoginScreen(),
  );

  static Map<String, dynamic> _args(GoRouterState state) {
    return (state.extra as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ValueListenableBuilder<MathiviaPalette>(
        valueListenable: AppPreferences.palette,
        builder: (context, palette, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.darkMode,
            builder: (context, isDark, _) {
              // Status bar / nav bar icon color is OS-level chrome, not part
              // of Flutter's ThemeData -- it has to be re-applied by hand
              // whenever dark mode toggles, or the icons stay whatever
              // brightness they were set to at launch (dark icons on a now-
              // dark background, which is invisible).
              final colors =
                  isDark ? SemanticColors.dark : SemanticColors.light;
              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colors.pageBg,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ));

              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Mathiva',
                theme: isDark ? AppTheme.dark(palette) : AppTheme.light(palette),
                routerConfig: _router,
              );
            },
          );
        },
      ),
    );
  }
}
