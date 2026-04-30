class Exam {
  final String id;
  final String title;
  final String subject;
  final String subjectId;
  final int? durationMinutes;
  final int grade; // 0 for all, 1, 2, 3 for secondary
  final List<Question> questions;
  final bool isPublished; // false = draft, true = published

  const Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.subjectId,
    this.durationMinutes,
    this.grade = 1,
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
      questions: questions ?? this.questions,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'title': title,
      'subject': subject,
      'subjectId': subjectId,
      'grade': grade,
      'questions': questions.map((q) => q.toJson()).toList(),
      'isPublished': isPublished,
    };
    if (durationMinutes != null) {
      json['durationMinutes'] = durationMinutes;
      json['d'] = durationMinutes;
    }
    return json;
  }

  Map<String, dynamic> toMinifiedJson() {
    final json = <String, dynamic>{
      'id': id,
      't': title,
      's': subject,
      'si': subjectId,
      'g': grade,
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
      questions: (json['q'] as List)
          .map((q) => Question.fromMinifiedJson(q as Map<String, dynamic>))
          .toList(),
      isPublished: json['p'] == 1,
    );
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    final List<Question> flattenedQuestions = [];
    final rawItems = json['questions'] as List;

    for (var item in rawItems) {
      final mapItem = item as Map<String, dynamic>;

      if (mapItem.containsKey('passage') && mapItem.containsKey('questions')) {
        // Handle Block structure: { "passage": "...", "questions": [...] }
        final blockPassage = mapItem['passage'] as String?;
        final blockQuestions = mapItem['questions'] as List;

        for (var qJson in blockQuestions) {
          final qMap = qJson as Map<String, dynamic>;
          final q = Question.fromJson(qMap);

          // Question's own passage takes precedence over block passage
          if (q.passage == null && blockPassage != null) {
            flattenedQuestions.add(q.copyWith(passage: blockPassage));
          } else {
            flattenedQuestions.add(q);
          }
        }
      } else {
        // Handle Direct Question structure: { "id": "...", "text": "...", ... }
        flattenedQuestions.add(Question.fromJson(mapItem));
      }
    }

    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      subjectId: json['subjectId'] as String? ?? 'nahw',
      durationMinutes: json['durationMinutes'] as int?,
      grade: json['grade'] as int? ?? 0,
      questions: flattenedQuestions,
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }

  factory Exam.mock() {
    return Exam(
      id: '1',
      title: 'اختبار النحو_unit 1',
      subject: 'النحو',
      subjectId: 'nahw',
      durationMinutes: 30,
      questions: [
        const Question(
          id: 'q1',
          text: 'ما الفكرة الرئيسية للفقرة السابقة؟',
          passage:
              'العربية لغة شريفة، نزل بها القرآن الكريم، وهي لغة أهل الجنة. إن الحفاظ على اللغة العربية هو حفاظ على الهوية الإسلامية والعربية. ويجب علينا أن نتعلم قواعدها ونطبقها في حديثنا وكتابتنا.',
          options: [
            Option(
              id: 'o1',
              text: 'أهمية اللغة العربية والحفاظ عليها',
              isCorrect: true,
            ),
            Option(
              id: 'o2',
              text: 'تاريخ نزول القرآن الكريم',
              isCorrect: false,
            ),
            Option(id: 'o3', text: 'اللغة العربية في الجنة', isCorrect: false),
            Option(
              id: 'o4',
              text: 'كيفية تعلم القواعد النحوية',
              isCorrect: false,
            ),
          ],
        ),
        const Question(
          id: 'q2',
          text:
              'لماذا اعتبر الكاتب الحفاظ على اللغة العربية حفاظًا على الهوية؟',
          passage:
              'العربية لغة شريفة، نزل بها القرآن الكريم، وهي لغة أهل الجنة. إن الحفاظ على اللغة العربية هو حفاظ على الهوية الإسلامية والعربية. ويجب علينا أن نتعلم قواعدها ونطبقها في حديثنا وكتابتنا.',
          options: [
            Option(
              id: 'o5',
              text: 'لأنها لغة القرآن وأهل الجنة',
              isCorrect: true,
            ),
            Option(id: 'o6', text: 'لأنها صعبة التعلم', isCorrect: false),
            Option(id: 'o7', text: 'لأنها منتشرة في العالم', isCorrect: false),
            Option(id: 'o8', text: 'لأنها لغة قديمة', isCorrect: false),
          ],
        ),
        const Question(
          id: 'q3',
          text: 'ماذا يجب علينا تجاه اللغة العربية حسب النص؟',
          passage:
              'العربية لغة شريفة، نزل بها القرآن الكريم، وهي لغة أهل الجنة. إن الحفاظ على اللغة العربية هو حفاظ على الهوية الإسلامية والعربية. ويجب علينا أن نتعلم قواعدها ونطبقها في حديثنا وكتابتنا.',
          options: [
            Option(id: 'o9', text: 'تعلم قواعدها وتطبيقها', isCorrect: true),
            Option(id: 'o10', text: 'قراءتها فقط', isCorrect: false),
            Option(id: 'o11', text: 'كتابة القصائد بها', isCorrect: false),
            Option(id: 'o12', text: 'ترجمتها للغات أخرى', isCorrect: false),
          ],
        ),
      ],
      isPublished: true,
    );
  }
}

class Question {
  final String id;
  final String text;
  final String? passage;
  final List<Option> options;

  const Question({
    required this.id,
    required this.text,
    this.passage,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      passage: json['passage'] as String?,
      options: (json['options'] as List)
          .map((o) => Option.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
  Question copyWith({
    String? id,
    String? text,
    String? passage,
    List<Option>? options,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      passage: passage ?? this.passage,
      options: options ?? this.options,
    );
  }

  Question shuffled() {
    final shuffledOptions = List<Option>.from(options)..shuffle();
    return copyWith(options: shuffledOptions);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'passage': passage,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMinifiedJson() {
    final correctIndex = options.indexWhere((o) => o.isCorrect);
    return {
      'id': id,
      't': text,
      if (passage != null) 'p': passage,
      'o': options.map((o) => o.text).toList(),
      'a': correctIndex,
    };
  }

  factory Question.fromMinifiedJson(Map<String, dynamic> json) {
    final optionsList = (json['o'] as List).cast<String>();
    final correctIndex = json['a'] as int;

    return Question(
      id: json['id'] as String,
      text: json['t'] as String,
      passage: json['p'] as String?,
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

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  Option copyWith({String? id, String? text, bool? isCorrect}) {
    return Option(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isCorrect': isCorrect};
  }
}
