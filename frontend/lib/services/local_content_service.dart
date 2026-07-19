import '../data/local_mathiva_data.dart';
import '../models/mathiva_models.dart';

class LocalContentService {
  List<MathSubject> getSubjects() => LocalMathivaData.subjects;

  MathSubject getSubject(String id) =>
      getSubjects().firstWhere((subject) => subject.id == id);

  MathTopic getTopic(String subjectId, String topicId) {
    return getSubject(subjectId)
        .topics
        .firstWhere((topic) => topic.id == topicId);
  }

  MathLesson getLesson(String subjectId, String topicId, String lessonId) {
    return getTopic(subjectId, topicId)
        .lessons
        .firstWhere((lesson) => lesson.id == lessonId);
  }

  Concept getConcept(
      String subjectId, String topicId, String lessonId, String conceptId) {
    return getLesson(subjectId, topicId, lessonId)
        .concepts
        .firstWhere((concept) => concept.id == conceptId);
  }

  List<MathTopic> allTopics() =>
      getSubjects().expand((subject) => subject.topics).toList();

  /// Every concept in the curriculum, each tagged with its full location in the
  /// content tree. Sent to the backend's /quiz/review-next so it can pick what
  /// the student should review and still attribute the attempt correctly (the
  /// content tree lives here in the app, not the backend).
  List<Map<String, String>> allConceptsWithContext() {
    final out = <Map<String, String>>[];
    for (final subject in getSubjects()) {
      for (final topic in subject.topics) {
        for (final lesson in topic.lessons) {
          for (final concept in lesson.concepts) {
            out.add({
              'concept_id': concept.id,
              'subject_id': subject.id,
              'topic_id': topic.id,
              'lesson_id': lesson.id,
            });
          }
        }
      }
    }
    return out;
  }
}
