import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';

class ExamEditorState extends ChangeNotifier {
  String examId;
  String title;
  String selectedCategoryId;
  int selectedGrade;
  int durationMinutes;
  bool durationEnabled;
  List<Question> questions;
  List<QuestionSettings> questionSettings;
  bool isPublished;
  int currentQuestionIndex;
  bool showPreview;
  int activeSidebarIndex = 0; // 0 for Settings, 1 for Paragraphs
  bool isMobileSettingsMode = false;
  List<Map<String, String>> passages;
  final Map<String, String> _passageCache;

  ExamEditorState({
    required this.examId,
    required this.title,
    required this.selectedCategoryId,
    required this.selectedGrade,
    required this.durationMinutes,
    required this.durationEnabled,
    required this.questions,
    required this.questionSettings,
    required this.isPublished,
    required this.currentQuestionIndex,
    required this.showPreview,
    required this.passages,
    Map<String, String>? passageCache,
  }) : _passageCache = passageCache ?? {};

  String _generateUuid() {
    return 'uuid_${DateTime.now().millisecondsSinceEpoch}_${questions.length}';
  }

  factory ExamEditorState.fromExam(Exam exam) {
    final questionSettings = <QuestionSettings>[];
    for (var i = 0; i < exam.questions.length; i++) {
      questionSettings.add(const QuestionSettings());
    }

    return ExamEditorState(
      examId: exam.id,
      title: exam.title,
      selectedCategoryId: exam.subjectId,
      selectedGrade: exam.grade,
      durationMinutes: exam.durationMinutes ?? 30,
      durationEnabled: exam.durationMinutes != null,
      questions: List.from(exam.questions),
      questionSettings: questionSettings,
      isPublished: exam.isPublished,
      currentQuestionIndex: -1,
      showPreview: false,
      passages: [],
      passageCache: {},
    );
  }

  factory ExamEditorState.empty() {
    final defaultCategoryId = CategoryMetadata.categories.isNotEmpty
        ? CategoryMetadata.categories.first.id
        : 'nahw';

    return ExamEditorState(
      examId: 'exam_${DateTime.now().millisecondsSinceEpoch}',
      title: '',
      selectedCategoryId: defaultCategoryId,
      selectedGrade: 1,
      durationMinutes: 30,
      durationEnabled: true,
      questions: [],
      questionSettings: [],
      isPublished: false,
      currentQuestionIndex: -1,
      showPreview: false,
      passages: [],
      passageCache: {},
    );
  }

  void addNewQuestion() {
    final newQuestion = Question(
      id: _generateUuid(),
      text: '',
      options: [
        Option(id: '${_generateUuid()}_o1', text: '', isCorrect: true),
        Option(id: '${_generateUuid()}_o2', text: '', isCorrect: false),
        Option(id: '${_generateUuid()}_o3', text: '', isCorrect: false),
        Option(id: '${_generateUuid()}_o4', text: '', isCorrect: false),
      ],
    );
    questions.add(newQuestion);
    currentQuestionIndex = questions.length - 1;
    notifyListeners();
  }

  void deleteQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      questions.removeAt(index);
      if (index < questionSettings.length) {
        questionSettings.removeAt(index);
      }
      if (currentQuestionIndex >= questions.length) {
        currentQuestionIndex = questions.length - 1;
      }
      notifyListeners();
    }
  }

  void updateQuestion(int index, Question question) {
    if (index >= 0 && index < questions.length) {
      questions[index] = question;
      notifyListeners();
    }
  }

  void updateQuestionSettings(int index, QuestionSettings? settings) {
    if (index >= 0 && index < questions.length) {
      if (settings != null) {
        if (index < questionSettings.length) {
          questionSettings[index] = settings;
        } else {
          questionSettings.add(settings);
        }
      }
      notifyListeners();
    }
  }

  void duplicateQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      final original = questions[index];
      final duplicate = Question(
        id: _generateUuid(),
        text: original.text,
        passage: original.passage,
        options: original.options.map((o) => Option(
          id: _generateUuid(),
          text: o.text,
          isCorrect: o.isCorrect,
        )).toList(),
      );
      questions.insert(index + 1, duplicate);
      if (index < questionSettings.length) {
        final settings = questionSettings[index];
        questionSettings.insert(index + 1, settings);
      }
      notifyListeners();
    }
  }

  void reorderQuestions(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final question = questions.removeAt(oldIndex);
    questions.insert(newIndex, question);

    if (oldIndex < questionSettings.length) {
      final settings = questionSettings.removeAt(oldIndex);
      questionSettings.insert(newIndex, settings);
    }
    notifyListeners();
  }

  void addPassage(String title, String content) {
    final id = 'passage_${DateTime.now().millisecondsSinceEpoch}';
    passages.add({
      'id': id,
      'title': title,
      'content': content,
    });
    _passageCache[id] = content;
    notifyListeners();
  }

  void deletePassage(int index) {
    if (index >= 0 && index < passages.length) {
      final removed = passages.removeAt(index);
      _passageCache.remove(removed['id']);
      notifyListeners();
    }
  }

  String? getPassageValue(String? currentPassage) {
    if (currentPassage == null || currentPassage.isEmpty) return '';
    for (var p in passages) {
      if (p['content'] == currentPassage) return p['id'];
    }
    return '__custom__';
  }

  String? getPassageContent(String? passageId) {
    if (passageId == null || passageId.isEmpty || passageId == '__custom__') {
      return null;
    }
    if (_passageCache.containsKey(passageId)) {
      return _passageCache[passageId];
    }
    for (var p in passages) {
      if (p['id'] == passageId) {
        _passageCache[passageId] = p['content']!;
        return p['content'];
      }
    }
    return null;
  }

  bool isSavedPassage(String? passageId) {
    if (passageId == null || passageId.isEmpty || passageId == '__custom__') {
      return false;
    }
    if (_passageCache.containsKey(passageId)) {
      return true;
    }
    for (var p in passages) {
      if (p['id'] == passageId) {
        return true;
      }
    }
    return false;
  }

  ExamValidationResult validate() {
    if (title.isEmpty) {
      return ExamValidationResult.error('يرجى إدخال عنوان الامتحان');
    }
    if (questions.isEmpty) {
      return ExamValidationResult.error('يرجى إضافة سؤال واحد على الأقل');
    }
    for (var i = 0; i < questions.length; i++) {
      final nonEmptyOptions = questions[i].options.where((o) => o.text.isNotEmpty).toList();
      if (nonEmptyOptions.length < 2) {
        return ExamValidationResult.error('يرجى إدخال خيارين على الأقل للسؤال ${i + 1}');
      }
      final uniqueOptions = nonEmptyOptions.map((o) => o.text.trim()).toSet();
      if (uniqueOptions.length != nonEmptyOptions.length) {
        return ExamValidationResult.error('الخيارات متكررة في السؤال ${i + 1} - يرجى التأكد من أن كل خيار فريد');
      }
    }
    for (var i = 0; i < questions.length; i++) {
      if (!questions[i].options.any((o) => o.isCorrect && o.text.isNotEmpty)) {
        return ExamValidationResult.error('يرجى تحديد إجابة صحيحة لكل سؤال ${i + 1}');
      }
    }
    return ExamValidationResult.valid();
  }

  Exam toExam({bool publish = false}) {
    CategoryMetadata? category;
    try {
      category = CategoryMetadata.categories.firstWhere(
        (c) => c.id == selectedCategoryId,
      );
    } catch (_) {
      category = CategoryMetadata.categories.isNotEmpty
          ? CategoryMetadata.categories.first
          : null;
    }

    final subject = category?.name ?? 'غير محدد';
    final subjectId = selectedCategoryId.isNotEmpty ? selectedCategoryId : 'nahw';

    return Exam(
      id: examId,
      title: title,
      subject: subject,
      subjectId: subjectId,
      durationMinutes: durationEnabled ? durationMinutes : null,
      grade: selectedGrade,
      questions: questions,
      isPublished: publish,
    );
  }

  void setShowPreview(bool value) {
    showPreview = value;
    notifyListeners();
  }

  void setActiveSidebarIndex(int index) {
    activeSidebarIndex = index;
    notifyListeners();
  }

  void setMobileSettingsMode(bool value) {
    isMobileSettingsMode = value;
    notifyListeners();
  }

  void notifyChange() {
    notifyListeners();
  }
}

class ExamValidationResult {
  final bool isValid;
  final String? errorMessage;

  ExamValidationResult._({required this.isValid, this.errorMessage});

  factory ExamValidationResult.valid() => ExamValidationResult._(isValid: true);
  factory ExamValidationResult.error(String message) =>
      ExamValidationResult._(isValid: false, errorMessage: message);
}