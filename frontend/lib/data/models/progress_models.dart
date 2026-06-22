// ignore_for_file: non_constant_identifier_names

class SubjectProgress {
  final String subject_id;
  final int mastery_percent;
  final int topics_completed;
  SubjectProgress({required this.subject_id, required this.mastery_percent, required this.topics_completed});
  factory SubjectProgress.fromJson(Map<String, dynamic> json) => SubjectProgress(
    subject_id: json['subject_id'],
    mastery_percent: json['mastery_percent'],
    topics_completed: json['topics_completed'],
  );
}

class StudentProgress {
  final int points_total;
  final int streak_days;
  final List<SubjectProgress> subjects;
  StudentProgress({required this.points_total, required this.streak_days, required this.subjects});
  factory StudentProgress.fromJson(Map<String, dynamic> json) => StudentProgress(
    points_total: json['points_total'],
    streak_days: json['streak_days'],
    subjects: (json['subjects'] as List).map((s) => SubjectProgress.fromJson(s)).toList(),
  );
}

class TopicMastery {
  final String topic_id;
  final String topic_name;
  final int mastery_level;
  final String last_practiced;
  TopicMastery({required this.topic_id, required this.topic_name, required this.mastery_level, required this.last_practiced});
  factory TopicMastery.fromJson(Map<String, dynamic> json) => TopicMastery(
    topic_id: json['topic_id'],
    topic_name: json['topic_name'],
    mastery_level: json['mastery_level'],
    last_practiced: json['last_practiced'],
  );
}

class Badge {
  final String badge_id;
  final String name;
  final String earned_date;
  Badge({required this.badge_id, required this.name, required this.earned_date});
  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    badge_id: json['badge_id'],
    name: json['name'],
    earned_date: json['earned_date'],
  );
}

class Rewards {
  final int points;
  final List<Badge> badges;
  final String rank;
  Rewards({required this.points, required this.badges, required this.rank});
  factory Rewards.fromJson(Map<String, dynamic> json) => Rewards(
    points: json['points'],
    badges: (json['badges'] as List).map((b) => Badge.fromJson(b)).toList(),
    rank: json['rank'],
  );
}
