import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mathiva/core/constants/api_constants.dart';
import 'package:mathiva/data/repositories/interfaces/auth_repository.dart';
import 'package:mathiva/data/repositories/interfaces/progress_repository.dart';
import 'package:mathiva/data/repositories/interfaces/quiz_repository.dart';
import 'package:mathiva/data/repositories/interfaces/review_repository.dart';
import 'package:mathiva/data/repositories/interfaces/subject_repository.dart';
import 'package:mathiva/data/repositories/interfaces/tutor_repository.dart';
import 'package:mathiva/data/repositories/api/api_auth_repository.dart';
import 'package:mathiva/data/repositories/api/api_progress_repository.dart';
import 'package:mathiva/data/repositories/api/api_quiz_repository.dart';
import 'package:mathiva/data/repositories/api/api_review_repository.dart';
import 'package:mathiva/data/repositories/api/api_subject_repository.dart';
import 'package:mathiva/data/repositories/api/api_tutor_repository.dart';

// Dio provider for HTTP client
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: kBaseUrl));
});

// API Repository Providers
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => ApiAuthRepository(ref.read(dioProvider)));
final subjectRepositoryProvider = Provider<SubjectRepository>(
    (ref) => ApiSubjectRepository(ref.read(dioProvider)));
final tutorRepositoryProvider = Provider<TutorRepository>(
    (ref) => ApiTutorRepository(ref.read(dioProvider)));
final quizRepositoryProvider =
    Provider<QuizRepository>((ref) => ApiQuizRepository(ref.read(dioProvider)));
final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => ApiReviewRepository(ref.read(dioProvider)));
final progressRepositoryProvider = Provider<ProgressRepository>(
    (ref) => ApiProgressRepository(ref.read(dioProvider)));
