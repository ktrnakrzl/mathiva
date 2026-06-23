// ignore_for_file: non_constant_identifier_names

class TutorRequest {
  final String student_id;
  final String question;
  final String subject_id;
  final String topic_id;
  TutorRequest(
      {required this.student_id,
      required this.question,
      required this.subject_id,
      required this.topic_id});
  Map<String, dynamic> toJson() => {
        'student_id': student_id,
        'question': question,
        'subject_id': subject_id,
        'topic_id': topic_id,
      };
}

class TutorResponse {
  final String answer;
  final List<String> steps;
  final String topic_detected;
  final String difficulty;
  final List<String> source_chunks;
  TutorResponse(
      {required this.answer,
      required this.steps,
      required this.topic_detected,
      required this.difficulty,
      required this.source_chunks});
  factory TutorResponse.fromJson(Map<String, dynamic> json) => TutorResponse(
        answer: json['answer'],
        steps: List<String>.from(json['steps']),
        topic_detected: json['topic_detected'],
        difficulty: json['difficulty'],
        source_chunks: List<String>.from(json['source_chunks']),
      );
}
