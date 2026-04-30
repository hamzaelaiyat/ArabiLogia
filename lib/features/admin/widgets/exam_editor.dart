import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_panel.dart';
import 'package:arabilogia/features/admin/widgets/exam_preview_widget.dart';
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
  late List<QuestionSettings> _questionSettings;
  late bool _isPublished;
  late int _currentQuestionIndex;
  bool _showPreview = false;
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
      // Load settings from exam metadata if available, otherwise create defaults
      _questionSettings = _loadQuestionSettings(exam);
      _isPublished = exam.isPublished;
    } else {
      _examId = 'exam_${DateTime.now().millisecondsSinceEpoch}';
      _title = '';
      _selectedCategoryId = CategoryMetadata.categories.first.id;
      _selectedGrade = 1;
      _durationMinutes = 30;
      _durationEnabled = true;
      _questions = [];
      _questionSettings = [];
      _isPublished = false;
    }
    _currentQuestionIndex = -1;
  }

  List<QuestionSettings> _loadQuestionSettings(Exam exam) {
    // For now, return default settings for each question
    // In the future, this could load from exam metadata
    return List.generate(
      exam.questions.length,
      (_) => const QuestionSettings(),
    );
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
        if (index < _questionSettings.length) {
          _questionSettings.removeAt(index);
        }
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

  void updateQuestionSettings(int index, QuestionSettings? settings) {
    if (index >= 0 && index < _questions.length) {
      setState(() {
        if (settings != null) {
          if (index < _questionSettings.length) {
            _questionSettings[index] = settings;
          } else {
            _questionSettings.add(settings);
          }
        }
      });
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
    // Validate that each question has at least one correct answer
    for (var q in _questions) {
      if (!q.options.any((o) => o.isCorrect)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تحديد إجابة صحيحة لكل سؤال')),
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
    final bgColor = AppColors.background(context);
    final fgColor = AppColors.foreground(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppTokens.breakpointTablet;

        // Main content
        final content = isDesktop
            ? Row(
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
                      onDurationToggle: (v) =>
                          setState(() => _durationEnabled = v),
                      onAddPassage: addPassage,
                      onDeletePassage: deletePassage,
                      onCancel: widget.onCancel,
                      onSaveDraft: () => saveExam(publish: false),
                      onPublish: () => saveExam(publish: true),
                      onPreview: () => setState(() => _showPreview = true),
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
                      questionSettings: _questionSettings,
                      passages: _passages,
                      getPassageValue: getPassageValue,
                      getPassageContent: getPassageContent,
                      isSavedPassage: isSavedPassage,
                      onAddQuestion: addNewQuestion,
                      onDeleteQuestion: deleteQuestion,
                      onUpdateQuestion: updateQuestion,
                      onUpdateSettings: updateQuestionSettings,
                    ),
                  ),
                ],
              )
            : DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      color: bgColor,
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
                            onGradeChanged: (v) =>
                                setState(() => _selectedGrade = v),
                            onDurationChanged: (v) =>
                                setState(() => _durationMinutes = v),
                            onDurationToggle: (v) =>
                                setState(() => _durationEnabled = v),
                            onAddPassage: addPassage,
                            onDeletePassage: deletePassage,
                            onCancel: widget.onCancel,
                            onSaveDraft: () => saveExam(publish: false),
                            onPublish: () => saveExam(publish: true),
                            onPreview: () =>
                                setState(() => _showPreview = true),
                          ),
                          QuestionListPanel(
                            questions: _questions,
                            questionSettings: _questionSettings,
                            passages: _passages,
                            getPassageValue: getPassageValue,
                            getPassageContent: getPassageContent,
                            isSavedPassage: isSavedPassage,
                            isMobile: true,
                            onAddQuestion: addNewQuestion,
                            onDeleteQuestion: deleteQuestion,
                            onUpdateQuestion: updateQuestion,
                            onUpdateSettings: updateQuestionSettings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

        // Show preview overlay if enabled
        if (_showPreview) {
          return Stack(
            children: [
              content,
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showPreview = false),
                  child: Container(color: Colors.black54),
                ),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                    maxHeight: 600,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'معاينة الامتحان',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: fgColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _showPreview = false),
                              icon: Icon(Icons.close, color: fgColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: buildPreviewContent()),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return content;
      },
    );
  }

  /// Helper method to build preview content - called AFTER all helper methods are defined
  Widget buildPreviewContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final tabUnselectedColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: tabBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: tabUnselectedColor,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.phone_android, size: 20), text: 'جوال'),
                Tab(icon: Icon(Icons.tablet_android, size: 20), text: 'لوحي'),
                Tab(icon: Icon(Icons.desktop_windows, size: 20), text: 'حاسوب'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                ExamPreviewWidget(
                  child: buildPreviewExamContent(),
                  device: PreviewDevice.mobile,
                ),
                ExamPreviewWidget(
                  child: buildPreviewExamContent(),
                  device: PreviewDevice.tablet,
                ),
                ExamPreviewWidget(
                  child: buildPreviewExamContent(),
                  device: PreviewDevice.desktop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build the exam preview content with questions and settings
  Widget buildPreviewExamContent() {
    final fgColor = AppColors.foreground(context);
    final mutedColor = AppColors.mutedColor(context);

    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'لا توجد أسئلة للمعاينة',
          style: TextStyle(color: mutedColor),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        final settings = index < _questionSettings.length
            ? _questionSettings[index]
            : const QuestionSettings();
        return buildQuestionPreviewItem(question, settings, index);
      },
    );
  }

  /// Helper to build individual question preview with its settings
  Widget buildQuestionPreviewItem(
    Question question,
    QuestionSettings settings,
    int index,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);
    final surfaceColor = AppColors.surface(context);
    final mutedColor = AppColors.mutedColor(context);
    final style = settings.textStyle;

    final textStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
      color: QuestionTextStyle.textColors[style.colorIndex],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'س ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${settings.points.points} درجة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(question.text, style: textStyle),
          const SizedBox(height: 12),
          ...question.options.map((option) {
            final isCorrect = option.isCorrect;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.1)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.3)
                      : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.2)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.2)),
                      border: Border.all(
                        color: isCorrect ? AppColors.success : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isCorrect
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.success,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: style.fontSize - 2,
                        fontWeight: style.isBold
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: fgColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
