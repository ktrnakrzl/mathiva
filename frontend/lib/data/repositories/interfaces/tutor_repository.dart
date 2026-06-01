import 'package:mathiva/data/models/tutor_models.dart';

abstract class TutorRepository {
  Future<TutorResponse> askQuestion(TutorRequest request);
}
