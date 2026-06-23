import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/progress/mastery_heatmap_screen.dart';
import 'presentation/screens/progress/rewards_screen.dart';
import 'presentation/screens/quiz/quiz_screen.dart';
import 'presentation/screens/review/review_queue_screen.dart';
import 'presentation/screens/tutor/tutor_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/concept_progress_screen.dart';
import 'screens/concept_reading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/image_solver_screen.dart';
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
          builder: (_, __) => const SolutionScreen()),
      GoRoute(path: '/quiz', builder: (_, __) => const QuizScreen()),
      GoRoute(path: '/review', builder: (_, __) => const ReviewQueueScreen()),
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
      child: ValueListenableBuilder(
        valueListenable: AppPreferences.palette,
        builder: (context, palette, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Mathiva',
            theme: AppTheme.light(palette),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
