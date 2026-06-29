import '../models/mathiva_models.dart';
import '../repositories/progress_repository.dart';

/// Curriculum progress computed from real attempt history, replacing the
/// static `progress:` literals in `local_mathiva_data.dart`.
///
/// A concept is "mastered" once the user has gotten it correct at least once.
/// Lesson/topic/subject progress is the fraction of their concepts mastered.
/// These take a `Map<String, ConceptStat>` (build once via
/// `UserProgress.conceptStats`) so callers don't re-scan the list per concept.

bool isConceptMastered(
  String conceptId,
  Map<String, ConceptStat> byConcept,
) {
  final stat = byConcept[conceptId];
  return stat != null && stat.correct > 0;
}

/// Fraction (0.0–1.0) of [lesson]'s concepts that are mastered.
double lessonProgress(MathLesson lesson, Map<String, ConceptStat> byConcept) {
  if (lesson.concepts.isEmpty) return 0;
  final mastered =
      lesson.concepts.where((c) => isConceptMastered(c.id, byConcept)).length;
  return mastered / lesson.concepts.length;
}

/// A lesson counts as complete when every one of its concepts is mastered.
bool isLessonComplete(MathLesson lesson, Map<String, ConceptStat> byConcept) {
  if (lesson.concepts.isEmpty) return false;
  return lesson.concepts.every((c) => isConceptMastered(c.id, byConcept));
}

/// Fraction (0.0–1.0) of [topic]'s concepts (across all its lessons) mastered.
double topicProgress(MathTopic topic, Map<String, ConceptStat> byConcept) {
  final concepts = topic.lessons.expand((l) => l.concepts).toList();
  if (concepts.isEmpty) return 0;
  final mastered =
      concepts.where((c) => isConceptMastered(c.id, byConcept)).length;
  return mastered / concepts.length;
}

/// Fraction (0.0–1.0) of [subject]'s concepts (across all topics/lessons)
/// mastered.
double subjectProgress(MathSubject subject, Map<String, ConceptStat> byConcept) {
  final concepts = subject.topics
      .expand((t) => t.lessons)
      .expand((l) => l.concepts)
      .toList();
  if (concepts.isEmpty) return 0;
  final mastered =
      concepts.where((c) => isConceptMastered(c.id, byConcept)).length;
  return mastered / concepts.length;
}

/// "X/Y" lesson-completion string for a subject (e.g. "3/14").
String lessonsCompletedFraction(
  MathSubject subject,
  Map<String, ConceptStat> byConcept,
) {
  final lessons = subject.topics.expand((t) => t.lessons).toList();
  final completed =
      lessons.where((l) => isLessonComplete(l, byConcept)).length;
  return '$completed/${lessons.length}';
}
