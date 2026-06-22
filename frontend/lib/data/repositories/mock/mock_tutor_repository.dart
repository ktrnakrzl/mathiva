import 'package:mathiva/data/models/tutor_models.dart';
import 'package:mathiva/data/repositories/interfaces/tutor_repository.dart';

class MockTutorRepository implements TutorRepository {
  @override
  Future<TutorResponse> askQuestion(TutorRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return TutorResponse(
      answer: 'A function is a relation where every input has exactly one output. Example: \\(f(x)=2x+1\\).',
      steps: const [
        'Identify the input values.',
        'Check whether any input is paired with more than one output.',
        'If every input has only one output, the relation is a function.',
      ],
      topic_detected: 'Functions',
      difficulty: 'Easy',
      source_chunks: const ['General Mathematics - Functions lesson'],
    );
  }
}
