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
}
