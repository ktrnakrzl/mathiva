import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/core/theme/app_theme.dart';
import 'package:mathiva/presentation/screens/auth/login_screen.dart';
import 'package:mathiva/presentation/screens/home/home_screen.dart';
import 'package:mathiva/presentation/screens/progress/mastery_heatmap_screen.dart';
import 'package:mathiva/presentation/screens/progress/rewards_screen.dart';
import 'package:mathiva/presentation/screens/quiz/answer_feedback_screen.dart';
import 'package:mathiva/presentation/screens/quiz/quiz_result_screen.dart';
import 'package:mathiva/presentation/screens/quiz/quiz_screen.dart';
import 'package:mathiva/presentation/screens/review/review_queue_screen.dart';
import 'package:mathiva/presentation/screens/subjects/subject_select_screen.dart';
import 'package:mathiva/presentation/screens/subjects/topic_list_screen.dart';
import 'package:mathiva/presentation/screens/tutor/tutor_screen.dart';

class MathivaApp extends StatelessWidget {
  const MathivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/subjects', builder: (context, state) => const SubjectSelectScreen()),
        GoRoute(
          path: '/subjects/:subjectId/topics',
          builder: (context, state) => TopicListScreen(subjectId: state.pathParameters['subjectId']!),
        ),
        GoRoute(path: '/tutor', builder: (context, state) => const TutorScreen()),
        GoRoute(path: '/quiz', builder: (context, state) => const QuizScreen()),
        GoRoute(path: '/answer-feedback', builder: (context, state) => const AnswerFeedbackScreen()),
        GoRoute(path: '/quiz-result', builder: (context, state) => const QuizResultScreen()),
        GoRoute(path: '/review', builder: (context, state) => const ReviewQueueScreen()),
        GoRoute(path: '/mastery', builder: (context, state) => const MasteryHeatmapScreen()),
        GoRoute(path: '/rewards', builder: (context, state) => const RewardsScreen()),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mathiva',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
