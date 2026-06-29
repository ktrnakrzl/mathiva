import '../progress_repository.dart';

/// Offline stand-in for [ProgressRepository] -- records nothing and returns a
/// small canned progress snapshot after a short delay, so the stats screens
/// can be exercised without a running backend (see `kUseMockBackend`).
class MockProgressRepository implements ProgressRepository {
  @override
  Future<void> submitAttempt({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
    String? selectedAnswer,
    required bool isCorrect,
    required int elapsedSeconds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // No-op: mock backend doesn't persist.
  }

  @override
  Future<GeneratedQuestion> fetchNextQuestion({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // A single canned question so the practice flow can be demoed offline.
    return GeneratedQuestion(
      questionId: 1,
      subjectId: subjectId,
      topicId: topicId,
      lessonId: lessonId,
      conceptId: conceptId,
      difficulty: difficulty,
      question: 'What is the mean of 4, 8, and 12?',
      choices: const ['8', '6', '12', '24'],
    );
  }

  @override
  Future<AnswerResult> submitAnswer({
    required int questionId,
    required String selectedAnswer,
    required int elapsedSeconds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return AnswerResult(
      attemptId: 1,
      isCorrect: selectedAnswer == '8',
      correctAnswer: '8',
      steps: const [
        'Add the values: 4 + 8 + 12 = 24.',
        'Divide by how many values there are: 24 / 3 = 8.',
      ],
    );
  }

  @override
  Future<UserProgress> getProgress() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const UserProgress(
      totalAttempts: 24,
      totalCorrect: 19,
      overallAccuracy: 79.2,
      currentStreakDays: 3,
      totalStudyTimeSeconds: 4260, // 1h 11m
      points: 190,
      bySubject: [
        SubjectStat(
          subjectId: 'general_mathematics',
          attempts: 24,
          correct: 19,
          accuracy: 79.2,
          totalElapsedSeconds: 4260,
        ),
      ],
      byTopic: [
        TopicStat(
          subjectId: 'general_mathematics',
          topicId: 'functions',
          attempts: 24,
          correct: 19,
          accuracy: 79.2,
        ),
      ],
      byTopicDifficulty: [
        TopicDifficultyStat(
          topicId: 'functions',
          difficulty: 'Easy',
          attempts: 12,
          correct: 11,
          accuracy: 91.7,
        ),
        TopicDifficultyStat(
          topicId: 'functions',
          difficulty: 'Medium',
          attempts: 8,
          correct: 6,
          accuracy: 75.0,
        ),
        TopicDifficultyStat(
          topicId: 'functions',
          difficulty: 'Hard',
          attempts: 4,
          correct: 2,
          accuracy: 50.0,
        ),
      ],
      byConcept: [
        ConceptStat(
          conceptId: 'evaluating_functions',
          attempts: 10,
          correct: 9,
          accuracy: 90.0,
        ),
      ],
      bestTimeByConcept: [
        ConceptBestTime(
          conceptId: 'evaluating_functions',
          bestElapsedSeconds: 42,
        ),
      ],
      last7Days: [
        DayActivity(date: '2026-06-19', attempts: 2),
        DayActivity(date: '2026-06-20', attempts: 0),
        DayActivity(date: '2026-06-21', attempts: 5),
        DayActivity(date: '2026-06-22', attempts: 3),
        DayActivity(date: '2026-06-23', attempts: 6),
        DayActivity(date: '2026-06-24', attempts: 4),
        DayActivity(date: '2026-06-25', attempts: 4),
      ],
      achievements: [
        Achievement(
          id: 'first_steps',
          label: 'First Steps',
          description: 'Solve your first problem',
          earned: true,
        ),
        Achievement(
          id: 'seven_day_streak',
          label: '7-Day Streak',
          description: 'Practice 7 days in a row',
          earned: false,
        ),
        Achievement(
          id: 'speed_demon',
          label: 'Speed Demon',
          description: 'Solve a problem in under 10 seconds',
          earned: true,
        ),
        Achievement(
          id: 'perfect_ten',
          label: 'On a Roll',
          description: 'Get 10 correct answers',
          earned: true,
        ),
        Achievement(
          id: 'topic_master',
          label: 'Topic Master',
          description: 'Reach 90% accuracy in any topic (5+ attempts)',
          earned: false,
        ),
        Achievement(
          id: 'dedicated_learner',
          label: 'Dedicated Learner',
          description: 'Log 1 hour of total study time',
          earned: true,
        ),
      ],
    );
  }
}
