// ignore_for_file: non_constant_identifier_names

class Subject {
  final String subject_id;
  final String name;
  final String grade_level;
  Subject({required this.subject_id, required this.name, required this.grade_level});
  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    subject_id: json['subject_id'],
    name: json['name'],
    grade_level: json['grade_level'],
  );
}

class Topic {
  final String topic_id;
  final String name;
  final List<String> difficulty_available;
  Topic({required this.topic_id, required this.name, required this.difficulty_available});
  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    topic_id: json['topic_id'],
    name: json['name'],
    difficulty_available: List<String>.from(json['difficulty_available']),
  );
}
