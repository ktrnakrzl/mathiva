import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../models/mathiva_models.dart';
import '../solver_repository.dart';
import 'auth_interceptor.dart';

/// Real implementation of [SolverRepository] — uploads the photo to the
/// FastAPI backend's `/api/solve-image` endpoint (pix2tex OCR -> SymPy solve
/// -> tutor explanation) and parses the result into a [PracticeProblem].
class ApiSolverRepository implements SolverRepository {
  // `/api/solve-image` is auth-gated, so the [AuthInterceptor] attaches the
  // logged-in user's JWT to the upload.
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  )..interceptors.add(AuthInterceptor());

  @override
  Future<PracticeProblem> solveImage(File image) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path),
    });

    final response = await _dio.post('/api/solve-image', data: formData);
    final data = response.data as Map<String, dynamic>;

    if (data['success'] != true) {
      throw SolverServiceException(
        data['error']?.toString() ?? 'Could not solve this problem.',
      );
    }

    final steps = (data['explanation']?.toString() ?? '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // The detected equation (pix2tex/typed input) is raw LaTeX with no
    // delimiters -- wrap it so MathRenderer picks it up as math, not plain text.
    final rawQuestion = data['latex']?.toString() ?? data['problem'].toString();

    return PracticeProblem(
      // The backend already builds a single ready-to-render, \(...\)-wrapped
      // LaTeX answer string (real fractions/roots via sympy.latex), so this
      // is used as-is instead of being reconstructed here.
      question: '\\($rawQuestion\\)',
      answer: data['answer']?.toString() ?? '',
      steps: steps.isNotEmpty ? steps : ['No explanation was returned.'],
    );
  }
}
