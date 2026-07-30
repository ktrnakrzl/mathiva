import 'package:cross_file/cross_file.dart';

import '../models/mathiva_models.dart';
import '../repositories/api/api_solver_repository.dart';
import '../repositories/solver_repository.dart';

export '../repositories/solver_repository.dart' show SolverServiceException;

/// Thin facade kept so existing call sites (e.g. `image_solver_screen.dart`)
/// didn't need to change when the solving logic moved to the repository
/// pattern. `repository` defaults to the real backend but can be swapped
/// (e.g. to `MockSolverRepository()`, see `main.dart`'s `kUseMockBackend` flag).
class SolverService {
  static SolverRepository repository = ApiSolverRepository();

  /// Uploads a photo of a math problem and returns the OCR'd equation
  /// solved step-by-step.
  static Future<PracticeProblem> solveImage(XFile image) =>
      repository.solveImage(image);
}
