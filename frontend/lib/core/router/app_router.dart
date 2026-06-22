import 'package:go_router/go_router.dart';
import 'package:mathiva_flutter/presentation/screens/auth/login_screen.dart';
import 'package:mathiva_flutter/presentation/screens/auth/signup_screen.dart';
import 'package:mathiva_flutter/presentation/screens/home/home_screen.dart';
import 'package:mathiva_flutter/presentation/screens/subjects/subjects_screen.dart';
import 'package:mathiva_flutter/presentation/screens/subjects/subject_detail_screen.dart';
import 'package:mathiva_flutter/presentation/screens/quiz/quiz_start_screen.dart';
import 'package:mathiva_flutter/presentation/screens/quiz/quiz_question_screen.dart';
import 'package:mathiva_flutter/presentation/screens/quiz/quiz_result_screen.dart';
import 'package:mathiva_flutter/presentation/screens/tutor/tutor_chat_screen.dart';
import 'package:mathiva_flutter/presentation/screens/progress/progress_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    // Home Route
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Subjects Routes
    GoRoute(
      path: '/subjects',
      builder: (context, state) => const SubjectsScreen(),
    ),
    GoRoute(
      path: '/subject/:subjectId',
      builder: (context, state) {
        final subjectId = state.pathParameters['subjectId']!;
        return SubjectDetailScreen(subjectId: subjectId);
      },
    ),
    // Quiz Routes
    GoRoute(
      path: '/quiz/:topicId',
      builder: (context, state) {
        final topicId = state.pathParameters['topicId']!;
        return QuizStartScreen(topicId: topicId);
      },
      routes: [
        GoRoute(
          path: 'session/:sessionId',
          builder: (context, state) {
            final topicId = state.pathParameters['topicId']!;
            final sessionId = state.pathParameters['sessionId']!;
            return QuizQuestionScreen(
              topicId: topicId,
              sessionId: sessionId,
            );
          },
        ),
        GoRoute(
          path: 'result/:sessionId',
          builder: (context, state) {
            final topicId = state.pathParameters['topicId']!;
            final sessionId = state.pathParameters['sessionId']!;
            return QuizResultScreen(
              topicId: topicId,
              sessionId: sessionId,
            );
          },
        ),
      ],
    ),
    // Tutor Routes
    GoRoute(
      path: '/tutor',
      builder: (context, state) => const TutorChatScreen(),
    ),
    GoRoute(
      path: '/tutor/topic/:topicId',
      builder: (context, state) {
        final topicId = state.pathParameters['topicId'];
        return TutorChatScreen(topicId: topicId);
      },
    ),
    GoRoute(
      path: '/tutor/question/:questionId',
      builder: (context, state) {
        final questionId = state.pathParameters['questionId'];
        return TutorChatScreen(questionId: questionId);
      },
    ),
    // Progress Route
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
  ],
);
