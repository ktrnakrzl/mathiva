import 'package:dio/dio.dart';
import 'package:mathiva/data/models/progress_models.dart';
import 'package:mathiva/data/repositories/interfaces/progress_repository.dart';

class ApiProgressRepository implements ProgressRepository {
  final Dio _dio;
  ApiProgressRepository(this._dio);

  @override
  Future<StudentProgress> getProgress(String studentId) async {
    final response = await _dio.get('/students/$studentId/progress');
    return StudentProgress.fromJson(response.data);
  }

  @override
  Future<List<TopicMastery>> getMastery(String studentId) async {
    final response = await _dio.get('/students/$studentId/mastery');
    return (response.data as List)
        .map((item) => TopicMastery.fromJson(item))
        .toList();
  }

  @override
  Future<Rewards> getRewards(String studentId) async {
    final response = await _dio.get('/students/$studentId/rewards');
    return Rewards.fromJson(response.data);
  }
}
