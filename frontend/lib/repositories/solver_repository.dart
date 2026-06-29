import 'dart:io';

import '../models/mathiva_models.dart';

/// Thrown when a [SolverRepository] can't produce a solved problem (e.g. the
/// backend OCR/solve pipeline failed, or returned `success: false`).
class SolverServiceException implements Exception {
  final String message;
  SolverServiceException(this.message);

  @override
  String toString() => message;
}

/// Contract for turning a photographed math problem into a solved,
/// step-by-step [PracticeProblem]. `ApiSolverRepository` hits the real
/// OCR+SymPy backend; `MockSolverRepository` returns canned data.
abstract class SolverRepository {
  Future<PracticeProblem> solveImage(File image);
}
