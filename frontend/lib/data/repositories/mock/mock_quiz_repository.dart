import 'package:mathiva/data/models/quiz_models.dart';
import 'package:mathiva/data/repositories/interfaces/quiz_repository.dart';

class MockQuizRepository implements QuizRepository {
  @override
  Future<QuizStartResponse> startQuiz(QuizStartRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return QuizStartResponse(
      quiz_id: 'quiz_001',
      questions: [
        QuizQuestion(question_id: 'q1', question_text: 'Evaluate \\(f(2)\\) if \\(f(x)=2x+1\\).', choices: const ['3', '4', '5', '6']),
        QuizQuestion(question_id: 'q2', question_text: 'Which relation is a function?', choices: const ['One input, one output', 'One input, two outputs', 'Vertical line circle', 'Repeated x with different y']),
      ],
    );
  }

  @override
  Future<AnswerResponse> submitAnswer(AnswerRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final correct = request.student_answer == '5' || request.student_answer == 'One input, one output';
    return AnswerResponse(
      is_correct: correct,
      correct_answer: request.question_id == 'q1' ? '5' : 'One input, one output',
      solution_steps: const ['Substitute the given value.', 'Simplify the expression.', 'Choose the matching answer.'],
    );
  }

  @override
  Future<QuizResult> finishQuiz(String quizId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return QuizResult(score: 2, total: 2, passed: true, wrong_items: const [], points_earned: 20);
  }
}
