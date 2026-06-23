import 'package:dio/dio.dart';
import 'package:mathiva/data/models/subject_models.dart';
import 'package:mathiva/data/repositories/interfaces/subject_repository.dart';

class ApiSubjectRepository implements SubjectRepository {
  final Dio _dio;
  ApiSubjectRepository(this._dio);

  @override
  Future<List<Subject>> getSubjects() async {
    final response = await _dio.get('/subjects');
    return (response.data as List)
        .map((item) => Subject.fromJson(item))
        .toList();
  }

  @override
  Future<List<Topic>> getTopics(String subjectId) async {
    final response = await _dio.get('/subjects/$subjectId/topics');
    return (response.data as List).map((item) => Topic.fromJson(item)).toList();
  }
}
