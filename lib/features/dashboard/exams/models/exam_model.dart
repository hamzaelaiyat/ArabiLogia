class Exam {
  final String id;
  final String title;
  final String subject;
  final String subjectId;
  final int? durationMinutes;
  final int grade; // 0 for all, 1, 2, 3 for secondary
  final int sortOrder; // Controls exam ordering for sequential unlocking
  final List<Question> questions;
  final bool isPublished; // false = draft, true = published

  const Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.subjectId,
    this.durationMinutes,
    this.grade = 1,
    this.sortOrder = 0,
    required this.questions,
    this.isPublished = false,
  });

  Exam copyWith({
    String? id,
    String? title,
    String? subject,
    String? subjectId,
    int? durationMinutes,
    bool clearDuration = false,
    int? grade,
    int? sortOrder,
    List<Question>? questions,
    bool? isPublished,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      subjectId: subjectId ?? this.subjectId,
      durationMinutes: clearDuration
          ? null
          : (durationMinutes ?? this.durationMinutes),
      grade: grade ?? this.grade,
      sortOrder: sortOrder ?? this.sortOrder,
      questions: questions ?? this.questions,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  Map<String, dynamic> toMinifiedJson() {
    final json = <String, dynamic>{
      'id': id,
      't': title,
      's': subject,
      'si': subjectId,
      'g': grade,
      'so': sortOrder,
      'q': questions.map((q) => q.toMinifiedJson()).toList(),
      'p': isPublished ? 1 : 0,
    };
    if (durationMinutes != null) {
      json['d'] = durationMinutes;
    }
    return json;
  }

  factory Exam.fromMinifiedJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['t'] as String,
      subject: json['s'] as String,
      subjectId: json['si'] as String,
      durationMinutes: json['d'] as int?,
      grade: json['g'] as int? ?? 0,
      sortOrder: json['so'] as int? ?? 0,
      questions: (json['q'] as List)
          .map((q) => Question.fromMinifiedJson(q as Map<String, dynamic>))
          .toList(),
      isPublished: json['p'] == 1,
    );
  }

}

class Question {
  final String id;
  final String text;
  final String? passage;
  final List<Option> options;
  final int points;

  const Question({
    required this.id,
    required this.text,
    this.passage,
    required this.options,
    this.points = 10,
  });

  Question copyWith({
    String? id,
    String? text,
    String? passage,
    List<Option>? options,
    int? points,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      passage: passage ?? this.passage,
      options: options ?? this.options,
      points: points ?? this.points,
    );
  }

  Question shuffled() {
    final shuffledOptions = List<Option>.from(options)..shuffle();
    return copyWith(options: shuffledOptions);
  }

  Map<String, dynamic> toMinifiedJson() {
    final correctIndex = options.indexWhere((o) => o.isCorrect);
    return {
      'id': id,
      't': text,
      if (passage != null) 'p': passage,
      'o': options.map((o) => o.text).toList(),
      'a': correctIndex,
      'pts': points,
    };
  }

  factory Question.fromMinifiedJson(Map<String, dynamic> json) {
    final optionsList = (json['o'] as List).cast<String>();
    final correctIndex = json['a'] as int;

    return Question(
      id: json['id'] as String,
      text: json['t'] as String,
      passage: json['p'] as String?,
      points: json['pts'] as int? ?? 10,
      options: List.generate(optionsList.length, (index) {
        return Option(
          id: 'o$index',
          text: optionsList[index],
          isCorrect: index == correctIndex,
        );
      }),
    );
  }
}

class Option {
  final String id;
  final String text;
  final bool isCorrect;

  const Option({required this.id, required this.text, required this.isCorrect});

  Option copyWith({String? id, String? text, bool? isCorrect}) {
    return Option(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
