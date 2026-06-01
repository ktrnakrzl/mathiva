// ignore_for_file: non_constant_identifier_names

class ReviewQuestion {
  final String question_id;
  final String question_text;
  final List<String> choices;
  final String topic_id;
  final String due_date;
  ReviewQuestion({required this.question_id, required this.question_text, required this.choices, required this.topic_id, required this.due_date});
  factory ReviewQuestion.fromJson(Map<String, dynamic> json) => ReviewQuestion(
    question_id: json['question_id'],
    question_text: json['question_text'],
    choices: List<String>.from(json['choices']),
    topic_id: json['topic_id'],
    due_date: json['due_date'],
  );
}

class ReviewResult {
  final String question_id;
  final bool is_correct;
  final int response_time_seconds;
  ReviewResult({required this.question_id, required this.is_correct, required this.response_time_seconds});
  Map<String, dynamic> toJson() => {'question_id': question_id, 'is_correct': is_correct, 'response_time_seconds': response_time_seconds};
}

class ReviewResultResponse {
  final String next_review_date;
  final double updated_ease_factor;
  ReviewResultResponse({required this.next_review_date, required this.updated_ease_factor});
  factory ReviewResultResponse.fromJson(Map<String, dynamic> json) => ReviewResultResponse(
    next_review_date: json['next_review_date'],
    updated_ease_factor: (json['updated_ease_factor'] as num).toDouble(),
  );
}
