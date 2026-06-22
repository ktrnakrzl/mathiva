import 'package:mathiva_flutter/data/repositories/question_repository.dart';
import 'package:mathiva_flutter/data/repositories/mock_data.dart';
import 'package:mathiva_flutter/core/models/question_model.dart';

class MockQuestionRepository implements QuestionRepository {
  final Map<String, QuizSession> _sessions = {};
  
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 500));

  final _questionBank = {
    'topic_polynomials': [
      MockData.sampleQuestions[0],
      QuestionModel(
        questionId: 'q1_alt',
        topicId: 'topic_polynomials',
        questionText: 'Factor the polynomial completely',
        latexFormula: r'x^4 - 16',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
        options: [
          r'(x^2-4)(x^2+4)',
          r'(x-2)(x+2)(x^2+4)',
          r'(x-4)(x^3+4x^2)',
          r'(x^2-2)(x^2+8)',
        ],
        correctAnswer: r'(x-2)(x+2)(x^2+4)',
        explanation: 'First factor out difference of squares, then continue',
        solutionSteps: '[]',
        pointsReward: 10,
      ),
    ],
    'topic_quadratic': [
      MockData.sampleQuestions[1],
      QuestionModel(
        questionId: 'q2_alt',
        topicId: 'topic_quadratic',
        questionText: 'Find the vertex of the parabola',
        latexFormula: r'y = x^2 - 4x + 3',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.multipleChoice,
        options: ['(2, -1)', '(2, 1)', '(-2, 19)', '(4, 3)'],
        correctAnswer: '(2, -1)',
        explanation: 'Use vertex formula or complete the square',
        solutionSteps: '[]',
        pointsReward: 8,
      ),
    ],
  };

  @override
  Future<List<QuestionModel>> getQuestionsByTopic(
    String topicId, {
    int limit = 10,
  }) async {
    await _delay();
    final questions = _questionBank[topicId] ?? [];
    return questions.take(limit).toList();
  }

  @override
  Future<QuestionModel> getQuestionById(String questionId) async {
    await _delay();
    for (var questions in _questionBank.values) {
      final question = questions.firstWhere(
        (q) => q.questionId == questionId,
        orElse: () => throw Exception('Question not found'),
      );
      return question;
    }
    throw Exception('Question not found');
  }

  @override
  Future<QuizSession> createQuizSession(
    String userId,
    String topicId,
    int numQuestions,
  ) async {
    await _delay();
    final questions = await getQuestionsByTopic(topicId, limit: numQuestions);
    
    final session = QuizSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      topicId: topicId,
      questions: questions,
      currentQuestionIndex: 0,
      userAnswers: [],
      isCorrectAnswers: [],
      scorePercentage: 0,
      isCompleted: false,
      startedAt: DateTime.now(),
      completedAt: null,
    );
    
    _sessions[session.sessionId] = session;
    return session;
  }

  @override
  Future<QuizSession> getQuizSession(String sessionId) async {
    await _delay();
    return _sessions[sessionId] ??
        (throw Exception('Session not found'));
  }

  @override
  Future<QuizSession> submitAnswer(
    String sessionId,
    int questionIndex,
    String answer,
  ) async {
    await _delay();
    final session = _sessions[sessionId];
    if (session == null) throw Exception('Session not found');

    final question = session.questions[questionIndex];
    final isCorrect = answer == question.correctAnswer;

    final updatedAnswers = [...session.userAnswers, answer];
    final updatedCorrect = [...session.isCorrectAnswers, isCorrect];
    final nextIndex = questionIndex + 1;
    final isSessionComplete = nextIndex >= session.questions.length;

    final scorePercentage = isSessionComplete
        ? ((updatedCorrect.where((c) => c).length / session.questions.length) *
                100)
            .toInt()
        : 0;

    final updatedSession = session.copyWith(
      currentQuestionIndex: nextIndex,
      userAnswers: updatedAnswers,
      isCorrectAnswers: updatedCorrect,
      scorePercentage: scorePercentage,
      isCompleted: isSessionComplete,
      completedAt: isSessionComplete ? DateTime.now() : null,
    );

    _sessions[sessionId] = updatedSession;
    return updatedSession;
  }

  @override
  Future<QuizSession> completeQuizSession(String sessionId) async {
    await _delay();
    final session = _sessions[sessionId];
    if (session == null) throw Exception('Session not found');

    final updatedSession = session.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    _sessions[sessionId] = updatedSession;
    return updatedSession;
  }

  @override
  Future<List<QuestionReview>> getReviewQueue(String userId) async {
    await _delay();
    return MockData.sampleQuestionReviewQueue;
  }

  @override
  Future<void> submitReview(
    String userId,
    String questionId,
    String userAnswer,
  ) async {
    await _delay();
    // In real implementation, update spaced repetition algorithm
  }
}

extension on QuizSession {
  QuizSession copyWith({
    String? sessionId,
    String? userId,
    String? topicId,
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    List<String>? userAnswers,
    List<bool>? isCorrectAnswers,
    int? scorePercentage,
    bool? isCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return QuizSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      isCorrectAnswers: isCorrectAnswers ?? this.isCorrectAnswers,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
