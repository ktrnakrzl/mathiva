import 'package:mathiva/core/models/models.dart';

class MockData {
  // Sample Users
  static final sampleUser = UserModel(
    userId: 'user123',
    username: 'johnstudent',
    email: 'john@ubnhs.edu.ph',
    gradeLevel: '11',
    totalPoints: 2450,
    streakDays: 7,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    lastLoginAt: DateTime.now(),
  );

  static final authResponse = AuthResponse(
    accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    refreshToken: 'refresh_token_sample_12345',
    user: sampleUser,
  );

  // Sample Subjects and Topics
  static final mathSubject = SubjectModel(
    subjectId: 'subj_math',
    name: 'Advanced Algebra',
    description:
        'Master advanced algebraic concepts and problem-solving techniques',
    topics: [
      TopicModel(
        topicId: 'topic_polynomials',
        name: 'Polynomial Equations',
        subjectId: 'subj_math',
        masteryPercentage: 72.5,
        questionsAttempted: 24,
        questionsCorrect: 17,
        lastReviewedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TopicModel(
        topicId: 'topic_quadratic',
        name: 'Quadratic Functions',
        subjectId: 'subj_math',
        masteryPercentage: 85.0,
        questionsAttempted: 30,
        questionsCorrect: 26,
        lastReviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TopicModel(
        topicId: 'topic_exponential',
        name: 'Exponential & Logarithmic Functions',
        subjectId: 'subj_math',
        masteryPercentage: 58.3,
        questionsAttempted: 15,
        questionsCorrect: 8,
        lastReviewedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      TopicModel(
        topicId: 'topic_trigonometry',
        name: 'Trigonometry',
        subjectId: 'subj_math',
        masteryPercentage: 40.0,
        questionsAttempted: 10,
        questionsCorrect: 4,
        lastReviewedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ],
    masteredTopics: 1,
  );

  static final sampleQuestions = [
    QuestionModel(
      questionId: 'q1',
      topicId: 'topic_polynomials',
      questionText: 'Find the roots of the polynomial equation',
      latexFormula: r'x^3 - 6x^2 + 11x - 6 = 0',
      difficulty: DifficultyLevel.medium,
      type: QuestionType.multipleChoice,
      options: ['x = 1, 2, 3', 'x = -1, 2, 3', 'x = 1, -2, 3', 'x = 1, 2, -3'],
      correctAnswer: 'x = 1, 2, 3',
      explanation: 'This polynomial can be factored as (x-1)(x-2)(x-3) = 0',
      solutionSteps:
          '[{"step": 1, "text": "Try to find rational roots using synthetic division"}, {"step": 2, "text": "Test x=1: 1-6+11-6=0, so x=1 is a root"}]',
      pointsReward: 10,
    ),
    QuestionModel(
      questionId: 'q2',
      topicId: 'topic_quadratic',
      questionText: 'Solve the quadratic equation',
      latexFormula: r'2x^2 + 5x - 3 = 0',
      difficulty: DifficultyLevel.easy,
      type: QuestionType.multipleChoice,
      options: ['x = 1/2, -3', 'x = -1/2, 3', 'x = 1, -3/2', 'x = -1, 3/2'],
      correctAnswer: 'x = 1/2, -3',
      explanation: 'Using the quadratic formula or factoring: (2x-1)(x+3) = 0',
      solutionSteps:
          '[{"step": 1, "text": "Use quadratic formula: x = (-b ± √(b²-4ac)) / 2a"}]',
      pointsReward: 8,
    ),
  ];

  static final sampleTutorMessages = [
    TutorMessage(
      messageId: 'msg1',
      sender: MessageSender.user,
      content: 'How do I solve x^2 - 5x + 6 = 0?',
      latexFormula: null,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      references: null,
    ),
    TutorMessage(
      messageId: 'msg2',
      sender: MessageSender.tutor,
      content:
          'Great question! Let me help you solve this quadratic equation. We can use factoring here. Notice that we need two numbers that multiply to 6 and add to -5. Those are -2 and -3.',
      latexFormula: r'x^2 - 5x + 6 = (x-2)(x-3) = 0',
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      references: [
        'polynomial_factoring_method.pdf',
        'quadratic_equations_guide.pdf'
      ],
    ),
    TutorMessage(
      messageId: 'msg3',
      sender: MessageSender.tutor,
      content:
          'So our solutions are x = 2 and x = 3. You can verify by substituting back into the original equation.',
      latexFormula: null,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      references: null,
    ),
  ];

  // Sample Progress Data
  static final sampleProgressSnapshot = ProgressSnapshot(
    userId: 'user123',
    totalPointsEarned: 2450,
    currentStreak: 7,
    longestStreak: 15,
    totalQuestionsAttempted: 125,
    totalQuestionsCorrect: 94,
    totalSessionsCompleted: 18,
    subjectProgress: {
      'subj_math': SubjectProgress(
        subjectId: 'subj_math',
        topicsMastered: 1,
        totalTopics: 4,
        overallMasteryPercentage: 63.9,
        topicMasteryMap: {
          'topic_polynomials': 72.5,
          'topic_quadratic': 85.0,
          'topic_exponential': 58.3,
          'topic_trigonometry': 40.0,
        },
        dailyActivity: List.generate(30, (i) {
          final date = DateTime.now().subtract(Duration(days: 29 - i));
          return DailyActivityPoint(
            date: date,
            pointsEarned: (50 + (i * 3) % 100),
            questionsAttempted: (3 + i % 5),
          );
        }),
      ),
    },
    lastActivityAt: DateTime.now(),
  );

  static final sampleRewardInfo = RewardInfo(
    level: 24,
    totalPointsForLevel: 2450,
    pointsNeededForNextLevel: 550,
    unlockedBadges: [
      Badge(
        badgeId: 'badge_first_steps',
        name: 'First Steps',
        description: 'Complete your first quiz',
        iconUrl: 'assets/badges/first_steps.png',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
        pointsReward: 50,
      ),
      Badge(
        badgeId: 'badge_streak_7',
        name: '7-Day Streak',
        description: 'Maintain a 7-day learning streak',
        iconUrl: 'assets/badges/streak_7.png',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
        pointsReward: 100,
      ),
    ],
    lockedBadges: [
      Badge(
        badgeId: 'badge_streak_30',
        name: '30-Day Streak',
        description: 'Maintain a 30-day learning streak',
        iconUrl: 'assets/badges/streak_30.png',
        isUnlocked: false,
        unlockedAt: null,
        pointsReward: 500,
      ),
    ],
  );

  static final sampleQuizSession = QuizSession(
    sessionId: 'session_quiz_001',
    userId: 'user123',
    topicId: 'topic_quadratic',
    questions: sampleQuestions,
    currentQuestionIndex: 0,
    userAnswers: [],
    isCorrectAnswers: [],
    scorePercentage: 0,
    isCompleted: false,
    startedAt: DateTime.now(),
    completedAt: null,
  );

  static final sampleQuestionReviewQueue = [
    QuestionReview(
      questionId: 'q1',
      userAnswer: 'x = 1, 2, 3',
      correctAnswer: 'x = 1, 2, 3',
      isCorrect: true,
      pointsEarned: 10,
      daysUntilNextReview: 3,
    ),
    QuestionReview(
      questionId: 'q3',
      userAnswer: 'x = 5',
      correctAnswer: 'x = 2, 3',
      isCorrect: false,
      pointsEarned: 0,
      daysUntilNextReview: 1,
    ),
  ];
}
