import 'package:mathiva/data/models/subject_models.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getSubjects();
  Future<List<Topic>> getTopics(String subjectId);
}
