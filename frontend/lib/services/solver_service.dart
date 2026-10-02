import 'package:cross_file/cross_file.dart';

import '../models/mathiva_models.dart';
import '../repositories/api/api_solver_repository.dart';
import '../repositories/solver_repository.dart';

export '../repositories/solver_repository.dart' show SolverServiceException;

/// Thin facade over the backend solver repository.
class SolverService {
  static SolverRepository repository = ApiSolverRepository();

  /// Uploads a photo of a math problem and returns the OCR'd equation
  /// solved step-by-step.
  static Future<PracticeProblem> solveImage(XFile image) =>
      repository.solveImage(image);
}
