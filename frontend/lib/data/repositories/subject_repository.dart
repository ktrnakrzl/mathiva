import 'package:mathiva/core/models/subject_model.dart';

abstract class SubjectRepository {
  Future<List<SubjectModel>> getAllSubjects();
  Future<SubjectModel> getSubjectById(String subjectId);
  Future<List<TopicModel>> getTopicsBySubject(String subjectId);
  Future<TopicModel> getTopicById(String topicId);
}
