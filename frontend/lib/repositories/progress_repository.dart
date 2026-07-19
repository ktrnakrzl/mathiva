/// Contract for recording a practice attempt and reading back the current
/// user's aggregated activity stats. `ApiProgressRepository` hits the real
/// FastAPI backend (`POST /api/quiz/submit`, `GET /api/user/progress`);
/// `MockProgressRepository` returns canned data so the UI can be developed
/// without a backend (see `kUseMockBackend`).
abstract class ProgressRepository {
  /// Records one completed practice problem. Fire-and-forget at the call
  /// site -- a failed submit shouldn't block the user seeing their result.
  Future<void> submitAttempt({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
    String? selectedAnswer,
    required bool isCorrect,
    required int elapsedSeconds,
  });

  /// Fetches the current user's aggregated progress across all attempts.
  Future<UserProgress> getProgress();

  /// Asks the server to generate a fresh, personalized question for this
  /// concept (`GET /api/quiz/next`). The response deliberately omits the
  /// correct answer -- it's revealed only after grading (see [submitAnswer]).
  Future<GeneratedQuestion> fetchNextQuestion({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required String conceptId,
    required String difficulty,
  });

  /// Asks the server to choose the next question ADAPTIVELY from the student's
  /// own history (`POST /api/quiz/next-adaptive`). Instead of the client picking
  /// the concept + difficulty, the server picks the concept (from
  /// [candidateConcepts]) and the difficulty that best fit what this student
  /// needs next. The returned [GeneratedQuestion] reports what was chosen.
  Future<GeneratedQuestion> fetchAdaptiveQuestion({
    required String subjectId,
    required String topicId,
    required String lessonId,
    required List<String> candidateConcepts,
  });

  /// Submits the chosen answer for a previously-served question
  /// (`POST /api/quiz/answer`). The server grades it against the answer it
  /// stored at generation time and returns the verdict + answer + steps.
  Future<AnswerResult> submitAnswer({
    required int questionId,
    required String selectedAnswer,
    required int elapsedSeconds,
  });
}

/// A server-generated question (`GET /api/quiz/next`). There is intentionally
/// no correct-answer field: the server keeps it private until the student
/// answers, so the client can't reveal or fake it (see [AnswerResult]).
class GeneratedQuestion {
  final int questionId;
  final String subjectId;
  final String topicId;
  final String lessonId;
  final String conceptId;
  final String difficulty;
  final String question;
  final List<String> choices;

  const GeneratedQuestion({
    required this.questionId,
    required this.subjectId,
    required this.topicId,
    required this.lessonId,
    required this.conceptId,
    required this.difficulty,
    required this.question,
    required this.choices,
  });

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) =>
      GeneratedQuestion(
        questionId: (json['question_id'] as num).toInt(),
        subjectId: json['subject_id'] as String,
        topicId: json['topic_id'] as String,
        lessonId: json['lesson_id'] as String,
        conceptId: json['concept_id'] as String,
        difficulty: json['difficulty'] as String,
        question: json['question'] as String,
        choices: ((json['choices'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

/// The graded result of one answer (`POST /api/quiz/answer`). This is the
/// first time the client learns the correct answer and the worked steps.
class AnswerResult {
  final int attemptId;
  final bool isCorrect;
  final String correctAnswer;
  final List<String> steps;

  const AnswerResult({
    required this.attemptId,
    required this.isCorrect,
    required this.correctAnswer,
    required this.steps,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        attemptId: (json['attempt_id'] as num).toInt(),
        isCorrect: json['is_correct'] as bool,
        correctAnswer: json['correct_answer'] as String,
        steps: ((json['steps'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

/// Mirrors the backend's `UserProgressResponse` (see `backend/app/api/quiz.py`).
/// Field names are camelCase here; `fromJson` maps the snake_case keys.
class UserProgress {
  final int totalAttempts;
  final int totalCorrect;
  final double overallAccuracy;
  final int currentStreakDays;
  final int totalStudyTimeSeconds;
  final int points;
  final List<SubjectStat> bySubject;
  final List<TopicStat> byTopic;
  final List<TopicDifficultyStat> byTopicDifficulty;
  final List<ConceptStat> byConcept;
  final List<ConceptBestTime> bestTimeByConcept;
  final List<DayActivity> last7Days;
  final List<Achievement> achievements;

  const UserProgress({
    required this.totalAttempts,
    required this.totalCorrect,
    required this.overallAccuracy,
    required this.currentStreakDays,
    required this.totalStudyTimeSeconds,
    required this.points,
    required this.bySubject,
    required this.byTopic,
    required this.byTopicDifficulty,
    required this.byConcept,
    required this.bestTimeByConcept,
    required this.last7Days,
    required this.achievements,
  });

  /// A brand-new user with no recorded attempts. Used as the safe default
  /// while loading or after a failed fetch so screens render real zeros
  /// rather than crashing or showing fake fallback numbers.
  factory UserProgress.empty() => const UserProgress(
        totalAttempts: 0,
        totalCorrect: 0,
        overallAccuracy: 0,
        currentStreakDays: 0,
        totalStudyTimeSeconds: 0,
        points: 0,
        bySubject: [],
        byTopic: [],
        byTopicDifficulty: [],
        byConcept: [],
        bestTimeByConcept: [],
        last7Days: [],
        achievements: [],
      );

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
        ((json[key] as List?) ?? const [])
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();

    return UserProgress(
      totalAttempts: (json['total_attempts'] as num?)?.toInt() ?? 0,
      totalCorrect: (json['total_correct'] as num?)?.toInt() ?? 0,
      overallAccuracy: (json['overall_accuracy'] as num?)?.toDouble() ?? 0,
      currentStreakDays: (json['current_streak_days'] as num?)?.toInt() ?? 0,
      totalStudyTimeSeconds:
          (json['total_study_time_seconds'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      bySubject: list('by_subject', SubjectStat.fromJson),
      byTopic: list('by_topic', TopicStat.fromJson),
      byTopicDifficulty:
          list('by_topic_difficulty', TopicDifficultyStat.fromJson),
      byConcept: list('by_concept', ConceptStat.fromJson),
      bestTimeByConcept:
          list('best_time_by_concept', ConceptBestTime.fromJson),
      last7Days: list('last_7_days', DayActivity.fromJson),
      achievements: list('achievements', Achievement.fromJson),
    );
  }

  /// Convenience: concept_id -> ConceptStat, built once per use.
  Map<String, ConceptStat> get conceptStats =>
      {for (final c in byConcept) c.conceptId: c};
}

class SubjectStat {
  final String subjectId;
  final int attempts;
  final int correct;
  final double accuracy;
  final int totalElapsedSeconds;

  const SubjectStat({
    required this.subjectId,
    required this.attempts,
    required this.correct,
    required this.accuracy,
    required this.totalElapsedSeconds,
  });

  factory SubjectStat.fromJson(Map<String, dynamic> json) => SubjectStat(
        subjectId: json['subject_id'] as String,
        attempts: (json['attempts'] as num).toInt(),
        correct: (json['correct'] as num).toInt(),
        accuracy: (json['accuracy'] as num).toDouble(),
        totalElapsedSeconds: (json['total_elapsed_seconds'] as num).toInt(),
      );
}

class TopicStat {
  final String subjectId;
  final String topicId;
  final int attempts;
  final int correct;
  final double accuracy;

  const TopicStat({
    required this.subjectId,
    required this.topicId,
    required this.attempts,
    required this.correct,
    required this.accuracy,
  });

  factory TopicStat.fromJson(Map<String, dynamic> json) => TopicStat(
        subjectId: json['subject_id'] as String,
        topicId: json['topic_id'] as String,
        attempts: (json['attempts'] as num).toInt(),
        correct: (json['correct'] as num).toInt(),
        accuracy: (json['accuracy'] as num).toDouble(),
      );
}

class TopicDifficultyStat {
  final String topicId;
  final String difficulty;
  final int attempts;
  final int correct;
  final double accuracy;

  const TopicDifficultyStat({
    required this.topicId,
    required this.difficulty,
    required this.attempts,
    required this.correct,
    required this.accuracy,
  });

  factory TopicDifficultyStat.fromJson(Map<String, dynamic> json) =>
      TopicDifficultyStat(
        topicId: json['topic_id'] as String,
        difficulty: json['difficulty'] as String,
        attempts: (json['attempts'] as num).toInt(),
        correct: (json['correct'] as num).toInt(),
        accuracy: (json['accuracy'] as num).toDouble(),
      );
}

class ConceptStat {
  final String conceptId;
  final int attempts;
  final int correct;
  final double accuracy;

  const ConceptStat({
    required this.conceptId,
    required this.attempts,
    required this.correct,
    required this.accuracy,
  });

  factory ConceptStat.fromJson(Map<String, dynamic> json) => ConceptStat(
        conceptId: json['concept_id'] as String,
        attempts: (json['attempts'] as num).toInt(),
        correct: (json['correct'] as num).toInt(),
        accuracy: (json['accuracy'] as num).toDouble(),
      );
}

class ConceptBestTime {
  final String conceptId;
  final int bestElapsedSeconds;

  const ConceptBestTime({
    required this.conceptId,
    required this.bestElapsedSeconds,
  });

  factory ConceptBestTime.fromJson(Map<String, dynamic> json) =>
      ConceptBestTime(
        conceptId: json['concept_id'] as String,
        bestElapsedSeconds: (json['best_elapsed_seconds'] as num).toInt(),
      );
}

class DayActivity {
  final String date; // "YYYY-MM-DD"
  final int attempts;

  const DayActivity({required this.date, required this.attempts});

  factory DayActivity.fromJson(Map<String, dynamic> json) => DayActivity(
        date: json['date'] as String,
        attempts: (json['attempts'] as num).toInt(),
      );
}

class Achievement {
  final String id;
  final String label;
  final String description;
  final bool earned;

  const Achievement({
    required this.id,
    required this.label,
    required this.description,
    required this.earned,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String,
        earned: json['earned'] as bool,
      );
}
