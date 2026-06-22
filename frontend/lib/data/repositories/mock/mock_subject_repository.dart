import 'package:mathiva/data/models/subject_models.dart';
import 'package:mathiva/data/repositories/interfaces/subject_repository.dart';

class MockSubjectRepository implements SubjectRepository {
  final List<Subject> _subjects = [
    Subject(subject_id: 'gen_math', name: 'General Mathematics', grade_level: 'Grade 11'),
    Subject(subject_id: 'stats', name: 'Statistics and Probability', grade_level: 'Grade 11'),
    Subject(subject_id: 'precalc', name: 'Pre-Calculus', grade_level: 'Grade 12'),
    Subject(subject_id: 'basic_calc', name: 'Basic Calculus', grade_level: 'Grade 12'),
  ];

  @override
  Future<List<Subject>> getSubjects() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _subjects;
  }

  @override
  Future<List<Topic>> getTopics(String subjectId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Topic(topic_id: '${subjectId}_functions', name: 'Functions', difficulty_available: const ['Easy', 'Medium', 'Hard']),
      Topic(topic_id: '${subjectId}_equations', name: 'Equations', difficulty_available: const ['Easy', 'Medium', 'Hard']),
      Topic(topic_id: '${subjectId}_applications', name: 'Applications', difficulty_available: const ['Easy', 'Medium', 'Hard']),
    ];
  }
}
