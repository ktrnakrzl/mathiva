class MathSubject {
  final String id;
  final String title;
  final String gradeLevel;
  final String iconText;
  final int progress;
  final List<MathTopic> topics;

  const MathSubject({
    required this.id,
    required this.title,
    required this.gradeLevel,
    required this.iconText,
    required this.progress,
    required this.topics,
  });
}

class MathTopic {
  final String id;
  final String title;
  final int progress;
  final List<MathLesson> lessons;

  const MathTopic({
    required this.id,
    required this.title,
    required this.progress,
    required this.lessons,
  });
}

class MathLesson {
  final String id;
  final String title;
  final String duration;
  final bool locked;
  final List<Concept> concepts;

  const MathLesson({
    required this.id,
    required this.title,
    required this.duration,
    required this.locked,
    required this.concepts,
  });
}

class Concept {
  final String id;
  final String title;
  final String definition;
  final String formula;
  final String example;
  final PracticeProblem problem;

  const Concept({
    required this.id,
    required this.title,
    required this.definition,
    required this.formula,
    required this.example,
    required this.problem,
  });
}

class PracticeProblem {
  final String question;
  final String answer;
  final List<String> steps;
  final List<String> choices;

  const PracticeProblem({
    required this.question,
    required this.answer,
    required this.steps,
    this.choices = const [],
  });
}
