import 'package:mathiva_flutter/core/models/question_model.dart';

abstract class QuestionRepository {
  Future<List<QuestionModel>> getQuestionsByTopic(
    String topicId, {
    int limit = 10,
  });
  
  Future<QuestionModel> getQuestionById(String questionId);
  
  Future<QuizSession> createQuizSession(
    String userId,
    String topicId,
    int numQuestions,
  );
  
  Future<QuizSession> getQuizSession(String sessionId);
  
  Future<QuizSession> submitAnswer(
    String sessionId,
    int questionIndex,
    String answer,
  );
  
  Future<QuizSession> completeQuizSession(String sessionId);
  
  Future<List<QuestionReview>> getReviewQueue(String userId);
  
  Future<void> submitReview(
    String userId,
    String questionId,
    String userAnswer,
  );
}
