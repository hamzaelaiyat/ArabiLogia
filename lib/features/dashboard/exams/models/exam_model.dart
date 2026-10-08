import 'package:arabilogia/core/models/grade_metadata.dart';

class Exam {
  final String id;
  final String title;
  final String subject;
  final String subjectId;
  final int? durationMinutes;
  final int grade; // GradeMetadata.allGrades means every grade

  /// Every grade this exam is shared with. A single entry is an ordinary
  /// grade-specific exam; several entries mean one shared exam.
  final List<int> gradeIds;
  final int sortOrder; // Controls exam ordering for sequential unlocking
  final int level; // 1=easy(85%), 2=medium(75%), 3=hard(60%)
  final List<Question> questions;
  final bool isPublished; // false = draft, true = published

  const Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.subjectId,
    this.durationMinutes,
    this.grade = GradeMetadata.defaultGradeId,
    this.gradeIds = const [],
    this.sortOrder = 0,
    this.level = 1,
    required this.questions,
    this.isPublished = false,
  });

  /// Grades this exam is actually shared with. Falls back to the legacy
  /// scalar [grade] for rows written before the `grade_ids` backfill.
  List<int> get effectiveGradeIds => gradeIds.isEmpty ? [grade] : gradeIds;

  /// Shared with every grade via the [GradeMetadata.allGrades] sentinel.
  bool get isSharedWithAllGrades =>
      effectiveGradeIds.contains(GradeMetadata.allGrades);

  /// One exam row serving more than one grade.
  bool get isSharedAcrossGrades => effectiveGradeIds.length > 1;

  bool isVisibleToGrade(int id) =>
      isSharedWithAllGrades || effectiveGradeIds.contains(id);

  int get passPercentage {
    switch (level) {
      case 2:
        return 75;
      case 3:
        return 60;
      default:
        return 85;
    }
  }

  Exam copyWith({
    String? id,
    String? title,
    String? subject,
    String? subjectId,
    int? durationMinutes,
    bool clearDuration = false,
    int? grade,
    List<int>? gradeIds,
    int? sortOrder,
    int? level,
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
      gradeIds: gradeIds ?? this.gradeIds,
      sortOrder: sortOrder ?? this.sortOrder,
      level: level ?? this.level,
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
      'grade_ids': effectiveGradeIds,
      'so': sortOrder,
      'lv': level,
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
      grade: json['g'] as int? ?? GradeMetadata.allGrades,
      gradeIds: GradeMetadata.parseGradeIds(
        json['grade_ids'],
        legacyGrade: json['g'] as int?,
      ),
      sortOrder: json['so'] as int? ?? 0,
      level: json['lv'] as int? ?? 1,
      questions: (json['q'] as List)
          .map((q) => Question.fromMinifiedJson(q as Map<String, dynamic>))
          .toList(),
      isPublished: json['p'] == 1,
    );
  }

  /// Rebuilds this exam with the server's answer key so the result
  /// screen can highlight the correct options. Pass the `answers`
  /// jsonb returned by get_exam_review: {questionIndex: correctOptionIndex}.
  Exam applyAnswers(Map<String, dynamic> answers) {
    final updatedQuestions = <Question>[];
    for (int i = 0; i < questions.length; i++) {
      final correctIndex = answers[i.toString()] as int?;
      if (correctIndex == null) {
        updatedQuestions.add(questions[i]);
        continue;
      }
      updatedQuestions.add(questions[i].withCorrectOptionId('o$correctIndex'));
    }
    return copyWith(questions: updatedQuestions);
  }
}

class Question {
  final String id;
  final String text;
  final String? passage;
  final List<Option> options;
  final int points;
  final String? explanation;

  const Question({
    required this.id,
    required this.text,
    this.passage,
    required this.options,
    this.points = 1,
    this.explanation,
  });

  Question copyWith({
    String? id,
    String? text,
    String? passage,
    List<Option>? options,
    int? points,
    String? explanation,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      passage: passage ?? this.passage,
      options: options ?? this.options,
      points: points ?? this.points,
      explanation: explanation ?? this.explanation,
    );
  }

  Question shuffled() {
    final shuffledOptions = List<Option>.from(options)..shuffle();
    return copyWith(options: shuffledOptions);
  }

  /// Marks the option whose id matches the given correct option id as
  /// correct and clears isCorrect on every other option. Used to build
  /// a reviewable Exam from the server's answer key (no client scoring).
  Question withCorrectOptionId(String correctOptionId) {
    final updated = options
        .map(
          (o) => Option(
            id: o.id,
            text: o.text,
            isCorrect: o.id == correctOptionId,
          ),
        )
        .toList();
    return copyWith(options: updated);
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
      if (explanation != null) 'e': explanation,
    };
  }

  factory Question.fromMinifiedJson(Map<String, dynamic> json) {
    final optionsList = (json['o'] as List).cast<String>();
    final correctIndex = json['a'] as int?;

    return Question(
      id: json['id'] as String,
      text: json['t'] as String,
      passage: json['p'] as String?,
      points: json['pts'] as int? ?? 1,
      explanation: json['e'] as String?,
      options: List.generate(optionsList.length, (index) {
        return Option(
          id: 'o$index',
          text: optionsList[index],
          isCorrect: correctIndex != null && index == correctIndex,
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
