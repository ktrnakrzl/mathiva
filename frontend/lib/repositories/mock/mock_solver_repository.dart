import 'package:cross_file/cross_file.dart';

import '../../data/local_mathiva_data.dart';
import '../../models/mathiva_models.dart';
import '../solver_repository.dart';

/// Offline stand-in for [SolverRepository] — ignores the photo and returns
/// the existing sample quadratic problem after a short simulated delay, so
/// the Image Solver UI can be exercised without a running backend.
class MockSolverRepository implements SolverRepository {
  @override
  Future<PracticeProblem> solveImage(XFile image) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return LocalMathivaData.quadraticProblem;
  }
}
