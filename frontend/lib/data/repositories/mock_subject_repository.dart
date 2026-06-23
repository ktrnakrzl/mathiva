import 'package:mathiva/data/repositories/subject_repository.dart';
import 'package:mathiva/data/repositories/mock_data.dart';
import 'package:mathiva/core/models/subject_model.dart';

class MockSubjectRepository implements SubjectRepository {
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 600));

  final _subjects = [
    MockData.mathSubject,
    SubjectModel(
      subjectId: 'subj_physics',
      name: 'Mechanics & Waves',
      description: 'Understand motion, forces, and wave phenomena',
      topics: [
        TopicModel(
          topicId: 'topic_motion',
          name: 'Kinematics',
          subjectId: 'subj_physics',
          masteryPercentage: 65.0,
          questionsAttempted: 18,
          questionsCorrect: 12,
          lastReviewedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        TopicModel(
          topicId: 'topic_forces',
          name: 'Dynamics & Forces',
          subjectId: 'subj_physics',
          masteryPercentage: 50.0,
          questionsAttempted: 12,
          questionsCorrect: 6,
          lastReviewedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ],
      masteredTopics: 0,
    ),
  ];

  @override
  Future<List<SubjectModel>> getAllSubjects() async {
    await _delay();
    return _subjects;
  }

  @override
  Future<SubjectModel> getSubjectById(String subjectId) async {
    await _delay();
    final subject = _subjects.firstWhere(
      (s) => s.subjectId == subjectId,
      orElse: () => throw Exception('Subject not found'),
    );
    return subject;
  }

  @override
  Future<List<TopicModel>> getTopicsBySubject(String subjectId) async {
    await _delay();
    final subject = await getSubjectById(subjectId);
    return subject.topics;
  }

  @override
  Future<TopicModel> getTopicById(String topicId) async {
    await _delay();
    for (var subject in _subjects) {
      final topic = subject.topics.firstWhere(
        (t) => t.topicId == topicId,
        orElse: () => throw Exception('Topic not found'),
      );
      return topic;
    }
    throw Exception('Topic not found');
  }
}
