import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_panel.dart';
import 'package:arabilogia/features/admin/widgets/question_list_panel.dart';

class ExamEditor extends StatefulWidget {
  final Exam? existingExam;
  final Function(Exam) onSave;
  final VoidCallback onCancel;

  const ExamEditor({
    super.key,
    this.existingExam,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ExamEditor> createState() => _ExamEditorState();
}

class _ExamEditorState extends State<ExamEditor> {
  late String _examId;
  late String _title;
  late String _selectedCategoryId;
  late int _selectedGrade;
  late int _durationMinutes;
  bool _durationEnabled = true;
  late List<Question> _questions;
  late bool _isPublished;
  late int _currentQuestionIndex;
  final List<Map<String, String>> _passages = [];

  final PageController _questionPageController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.existingExam != null) {
      final exam = widget.existingExam!;
      _examId = exam.id;
      _title = exam.title;
      _selectedCategoryId = exam.subjectId;
      _selectedGrade = exam.grade;
      _durationMinutes = exam.durationMinutes ?? 30;
      _durationEnabled = exam.durationMinutes != null;
      _questions = List.from(exam.questions);
      _isPublished = exam.isPublished;
    } else {
      _examId = 'exam_${DateTime.now().millisecondsSinceEpoch}';
      _title = '';
      _selectedCategoryId = CategoryMetadata.categories.first.id;
      _selectedGrade = 1;
      _durationMinutes = 30;
      _durationEnabled = true;
      _questions = [];
      _isPublished = false;
    }
    _currentQuestionIndex = -1;
  }

  @override
  void dispose() {
    _questionPageController.dispose();
    super.dispose();
  }

  void addNewQuestion() {
    final newQuestion = Question(
      id: 'q${_questions.length + 1}',
      text: '',
      options: [
        Option(id: 'o1', text: '', isCorrect: true),
        Option(id: 'o2', text: '', isCorrect: false),
        Option(id: 'o3', text: '', isCorrect: false),
        Option(id: 'o4', text: '', isCorrect: false),
      ],
    );
    setState(() {
      _questions.add(newQuestion);
      _currentQuestionIndex = _questions.length - 1;
    });
  }

  void deleteQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      setState(() {
        _questions.removeAt(index);
        if (_currentQuestionIndex >= _questions.length) {
          _currentQuestionIndex = _questions.length - 1;
        }
      });
    }
  }

  void updateQuestion(int index, Question question) {
    if (index >= 0 && index < _questions.length) {
      setState(() => _questions[index] = question);
    }
  }

  void addPassage(String title, String content) {
    setState(() {
      _passages.add({
        'id': 'passage_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'content': content,
      });
    });
  }

  void deletePassage(int index) {
    if (index >= 0 && index < _passages.length) {
      setState(() => _passages.removeAt(index));
    }
  }

  String? getPassageValue(String? currentPassage) {
    if (currentPassage == null || currentPassage.isEmpty) return '';
    for (var p in _passages) {
      if (p['content'] == currentPassage) return p['id'];
    }
    return '__custom__';
  }

  String? getPassageContent(String? passageId) {
    if (passageId == null || passageId.isEmpty || passageId == '__custom__')
      return null;
    for (var p in _passages) {
      if (p['id'] == passageId) return p['content'];
    }
    return null;
  }

  bool isSavedPassage(String? passageId) {
    if (passageId == null || passageId.isEmpty || passageId == '__custom__')
      return false;
    for (var p in _passages) {
      if (p['id'] == passageId) return true;
    }
    return false;
  }

  void saveExam({bool publish = false}) {
    if (_title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان الامتحان')),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة سؤال واحد على الأقل')),
      );
      return;
    }
    for (var q in _questions) {
      if (q.text.isEmpty || q.options.any((o) => o.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إكمال جميع حقول الأسئلة')),
        );
        return;
      }
    }
    final category = CategoryMetadata.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
    );
    final exam = Exam(
      id: _examId,
      title: _title,
      subject: category.name,
      subjectId: _selectedCategoryId,
      durationMinutes: _durationEnabled ? _durationMinutes : null,
      grade: _selectedGrade,
      questions: _questions,
      isPublished: publish,
    );
    widget.onSave(exam);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get potato mode settings for conditional UI rendering
    bool allowAnimations = true;
    bool allowShadows = true;
    bool allowGradients = true;
    bool enableSmoothScrolling = true;
    int maxItems = 50;

    try {
      final provider = Provider.of<PotatoModeProvider?>(context, listen: false);
      if (provider != null) {
        allowAnimations = provider.animationsEnabled;
        allowShadows = provider.shadowsEnabled;
        allowGradients = provider.fancyUIAEnabled;
        enableSmoothScrolling = provider.lazyLoadingEnabled;
        maxItems = provider.maxListItems;
      }
    } catch (_) {
      // Provider not available, use defaults
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppTokens.breakpointTablet;
        final isMobile = constraints.maxWidth < AppTokens.breakpointMobile;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 380,
                child: ExamSettingsPanel(
                  title: _title,
                  selectedCategoryId: _selectedCategoryId,
                  selectedGrade: _selectedGrade,
                  durationMinutes: _durationMinutes,
                  durationEnabled: _durationEnabled,
                  isPublished: _isPublished,
                  passages: _passages,
                  onTitleChanged: (v) => setState(() => _title = v),
                  onCategoryChanged: (v) =>
                      setState(() => _selectedCategoryId = v),
                  onGradeChanged: (v) => setState(() => _selectedGrade = v),
                  onDurationChanged: (v) =>
                      setState(() => _durationMinutes = v),
                  onDurationToggle: (v) => setState(() => _durationEnabled = v),
                  onAddPassage: addPassage,
                  onDeletePassage: deletePassage,
                  onCancel: widget.onCancel,
                  onSaveDraft: () => saveExam(publish: false),
                  onPublish: () => saveExam(publish: true),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              Expanded(
                flex: 3,
                child: QuestionListPanel(
                  questions: _questions,
                  passages: _passages,
                  getPassageValue: getPassageValue,
                  getPassageContent: getPassageContent,
                  isSavedPassage: isSavedPassage,
                  onAddQuestion: addNewQuestion,
                  onDeleteQuestion: deleteQuestion,
                  onUpdateQuestion: updateQuestion,
                ),
              ),
            ],
          );
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: isDark ? AppColors.bgDark : AppColors.bgLight,
                child: TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.mutedColor(context),
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
                    Tab(icon: Icon(Icons.quiz), text: 'الأسئلة'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ExamSettingsPanel(
                      title: _title,
                      selectedCategoryId: _selectedCategoryId,
                      selectedGrade: _selectedGrade,
                      durationMinutes: _durationMinutes,
                      durationEnabled: _durationEnabled,
                      isPublished: _isPublished,
                      passages: _passages,
                      isMobile: true,
                      onTitleChanged: (v) => setState(() => _title = v),
                      onCategoryChanged: (v) =>
                          setState(() => _selectedCategoryId = v),
                      onGradeChanged: (v) => setState(() => _selectedGrade = v),
                      onDurationChanged: (v) =>
                          setState(() => _durationMinutes = v),
                      onDurationToggle: (v) =>
                          setState(() => _durationEnabled = v),
                      onAddPassage: addPassage,
                      onDeletePassage: deletePassage,
                      onCancel: widget.onCancel,
                      onSaveDraft: () => saveExam(publish: false),
                      onPublish: () => saveExam(publish: true),
                    ),
                    QuestionListPanel(
                      questions: _questions,
                      passages: _passages,
                      getPassageValue: getPassageValue,
                      getPassageContent: getPassageContent,
                      isSavedPassage: isSavedPassage,
                      isMobile: true,
                      onAddQuestion: addNewQuestion,
                      onDeleteQuestion: deleteQuestion,
                      onUpdateQuestion: updateQuestion,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
