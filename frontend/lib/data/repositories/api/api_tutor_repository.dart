import 'package:dio/dio.dart';
import 'package:mathiva/data/models/tutor_models.dart';
import 'package:mathiva/data/repositories/interfaces/tutor_repository.dart';

class ApiTutorRepository implements TutorRepository {
  final Dio _dio;
  ApiTutorRepository(this._dio);

  @override
  Future<TutorResponse> askQuestion(TutorRequest request) async {
    final response = await _dio.post('/tutor/ask', data: request.toJson());
    return TutorResponse.fromJson(response.data);
  }
}
