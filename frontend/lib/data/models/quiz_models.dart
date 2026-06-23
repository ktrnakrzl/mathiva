// ignore_for_file: non_constant_identifier_names

class QuizStartRequest {
  final String student_id;
  final String subject_id;
  final String topic_id;
  final String difficulty;
  final int item_count;
  QuizStartRequest(
      {required this.student_id,
      required this.subject_id,
      required this.topic_id,
      required this.difficulty,
      required this.item_count});
  Map<String, dynamic> toJson() => {
        'student_id': student_id,
        'subject_id': subject_id,
        'topic_id': topic_id,
        'difficulty': difficulty,
        'item_count': item_count,
      };
}

class QuizQuestion {
  final String question_id;
  final String question_text;
  final List<String> choices;
  QuizQuestion(
      {required this.question_id,
      required this.question_text,
      required this.choices});
  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question_id: json['question_id'],
        question_text: json['question_text'],
        choices: List<String>.from(json['choices']),
      );
}

class QuizStartResponse {
  final String quiz_id;
  final List<QuizQuestion> questions;
  QuizStartResponse({required this.quiz_id, required this.questions});
  factory QuizStartResponse.fromJson(Map<String, dynamic> json) =>
      QuizStartResponse(
        quiz_id: json['quiz_id'],
        questions: (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
      );
}

class AnswerRequest {
  final String quiz_id;
  final String question_id;
  final String student_answer;
  AnswerRequest(
      {required this.quiz_id,
      required this.question_id,
      required this.student_answer});
  Map<String, dynamic> toJson() => {
        'quiz_id': quiz_id,
        'question_id': question_id,
        'student_answer': student_answer
      };
}

class AnswerResponse {
  final bool is_correct;
  final String correct_answer;
  final List<String> solution_steps;
  AnswerResponse(
      {required this.is_correct,
      required this.correct_answer,
      required this.solution_steps});
  factory AnswerResponse.fromJson(Map<String, dynamic> json) => AnswerResponse(
        is_correct: json['is_correct'],
        correct_answer: json['correct_answer'],
        solution_steps: List<String>.from(json['solution_steps']),
      );
}

class QuizResult {
  final int score;
  final int total;
  final bool passed;
  final List<String> wrong_items;
  final int points_earned;
  QuizResult(
      {required this.score,
      required this.total,
      required this.passed,
      required this.wrong_items,
      required this.points_earned});
  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        score: json['score'],
        total: json['total'],
        passed: json['passed'],
        wrong_items: List<String>.from(json['wrong_items']),
        points_earned: json['points_earned'],
      );
}
