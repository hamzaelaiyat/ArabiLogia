import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/text_block_editor_sheet.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/youtube_link_editor_sheet.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/add_content_sheet.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/exit_confirmation_sheet.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/block_preview_widget.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/block_row_widget.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/lecture_editor_mobile_app_bar.dart';
import 'package:arabilogia/features/admin/widgets/lecture_editor/lecture_editor_desktop_layout.dart';
import 'package:arabilogia/features/admin/widgets/inset_toggle.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:provider/provider.dart';

class LectureEditorScreen extends StatefulWidget {
  final Lecture? existingLecture;

  const LectureEditorScreen({super.key, this.existingLecture});

  @override
  State<LectureEditorScreen> createState() => _LectureEditorScreenState();
}

class _LectureEditorScreenState extends State<LectureEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _sortOrderController;
  late String _selectedCategoryId;
  late int _selectedGrade;
  late bool _isPublished;

  List<LectureContentBlock> _contentBlocks = [];
  List<Exam> _exams = [];
  int _activeSidebarIndex = 0;
  bool _isMobileContentView = true;
  Timer? _autosaveTimer;
  DateTime? _lastAutosaveAt;

  bool get _isEditing => widget.existingLecture != null;

  String get _draftKey =>
      'lecture_draft_${widget.existingLecture?.id ?? 'new'}';

  @override
  void initState() {
    super.initState();

    final lecture = widget.existingLecture;
    _titleController = TextEditingController(text: lecture?.title ?? '');
    _sortOrderController = TextEditingController(
      text: lecture != null ? lecture.sortOrder.toString() : '0',
    );
    _selectedCategoryId = lecture?.courseId ?? CategoryMetadata.categories.first.id;
    _selectedGrade = lecture?.grade ?? 1;
    _isPublished = lecture?.isPublished ?? false;
    _contentBlocks = lecture != null ? List.from(lecture.contentBlocks) : [];
    _titleController.addListener(_scheduleAutosave);
    _sortOrderController.addListener(_scheduleAutosave);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDraft());
    _loadExams();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    final lecture = widget.existingLecture;
    if (lecture != null && lecture.examIds.isNotEmpty) {
      final loaded = <Exam>[];
      for (var id in lecture.examIds) {
        final exam = await ExamRepository().loadExamById(_selectedCategoryId, id);
        if (exam != null) {
          loaded.add(exam);
        }
      }
      if (mounted) {
        setState(() {
          _exams = loaded;
        });
      }
    }
  }

  Lecture _currentLecture() {
    return Lecture(
      id: widget.existingLecture?.id ?? 'draft',
      title: _titleController.text.trim(),
      courseId: _selectedCategoryId,
      youtubeUrl: '',
      description: '',
      sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
      grade: _selectedGrade,
      isPublished: _isPublished,
      contentBlocks: _contentBlocks,
      examIds: _exams.map((e) => e.id).toList(),
    );
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), _autosaveDraft);
  }

  Future<void> _autosaveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(_currentLecture().toJson()));
    if (mounted) {
      setState(() => _lastAutosaveAt = DateTime.now());
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> _checkDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('توجد مسودة محفوظة تلقائياً لهذه المحاضرة'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'استعادة',
          onPressed: () => _restoreDraft(raw),
        ),
      ),
    );
  }

  void _restoreDraft(String raw) {
    try {
      final lecture = Lecture.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      setState(() {
        _titleController.text = lecture.title;
        _sortOrderController.text = lecture.sortOrder.toString();
        _selectedCategoryId = lecture.courseId;
        _selectedGrade = lecture.grade;
        _isPublished = lecture.isPublished;
        _contentBlocks = List.from(lecture.contentBlocks);
      });
      _loadExamsFromIds(lecture.examIds);
    } catch (_) {}
  }

  Future<void> _loadExamsFromIds(List<String> ids) async {
    final loaded = <Exam>[];
    for (var id in ids) {
      final exam = await ExamRepository().loadExamById(_selectedCategoryId, id);
      if (exam != null) {
        loaded.add(exam);
      }
    }
    if (mounted) {
      setState(() => _exams = loaded);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() {
        _isMobileContentView = false;
        _activeSidebarIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى التحقق من صحة إعدادات المحاضرة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      String derivedYoutubeUrl = '';
      String? derivedQuizId;
      String derivedDescription = '';

      for (var block in _contentBlocks) {
        if (block.type == BlockType.youtube && derivedYoutubeUrl.isEmpty) {
          derivedYoutubeUrl = block.content;
        } else if ((block.type == BlockType.quiz || block.type == BlockType.exam) && derivedQuizId == null) {
          derivedQuizId = block.content;
        } else if (block.type == BlockType.text && derivedDescription.isEmpty) {
          derivedDescription = block.content;
        }
      }

      if (derivedQuizId == null && _exams.isNotEmpty) {
        derivedQuizId = _exams.first.id;
      }

      final lecture = Lecture(
        id: widget.existingLecture?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        courseId: _selectedCategoryId,
        youtubeUrl: derivedYoutubeUrl,
        description: derivedDescription,
        quizId: derivedQuizId,
        sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
        grade: _selectedGrade,
        isPublished: _isPublished,
        contentBlocks: _contentBlocks,
        examIds: _exams.map((e) => e.id).toList(),
      );

      await LectureRepository().upsertLecture(lecture);
      await _clearDraft();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPublished ? 'تم حفظ ونشر المحاضرة بنجاح!' : 'تم حفظ المحاضرة بنجاح'),
          backgroundColor: _isPublished ? Colors.green : Colors.blue,
        ),
      );
      context.pop(lecture);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحفظ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onContentBlockSaved(LectureContentBlock block, int? index) {
    setState(() {
      if (index != null) {
        _contentBlocks[index] = block;
      } else {
        _contentBlocks.add(block);
      }
    });
    _scheduleAutosave();
  }

  Future<void> _showExamEditor({LectureContentBlock? existingBlock, int? index, bool isQuiz = true}) async {
    Exam? associatedExam;
    if (existingBlock != null && existingBlock.content.isNotEmpty) {
      associatedExam = await ExamRepository().loadExamById(_selectedCategoryId, existingBlock.content);
    }

    final examToPass = associatedExam ?? Exam(
      id: existingBlock?.content ?? 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: existingBlock?.metadata?['title'] ?? 'اختبار قصير (امتحن)',
      subject: CategoryMetadata.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => CategoryMetadata.categories.first,
      ).name,
      subjectId: _selectedCategoryId,
      grade: _selectedGrade,
      questions: [],
    );

    if (!mounted) return;

    final result = await context.push<Exam?>(
      AppRoutes.examEditor,
      extra: {
        'exam': examToPass,
        'hideCategoryAndGrade': true,
        'hidePoints': isQuiz,
        'hideTimer': isQuiz,
        'hideLevel': isQuiz,
      },
    );

    if (result != null && mounted) {
      final block = LectureContentBlock(
        id: existingBlock?.id ?? const Uuid().v4(),
        type: BlockType.quiz,
        content: result.id,
        metadata: {
          'title': result.title,
          'durationMinutes': null,
          'questionsCount': result.questions.length,
        },
      );
      setState(() {
        if (index != null) {
          _contentBlocks[index] = block;
        } else {
          _contentBlocks.add(block);
        }
      });
      _scheduleAutosave();
    }
  }

  Future<void> _showExamsTabEditor({Exam? existingExam}) async {
    final examToPass = existingExam ?? Exam(
      id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
      title: 'امتحان المحاضرة',
      subject: CategoryMetadata.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => CategoryMetadata.categories.first,
      ).name,
      subjectId: _selectedCategoryId,
      grade: _selectedGrade,
      questions: [],
    );

    if (!mounted) return;

    final result = await context.push<Exam?>(
      AppRoutes.examEditor,
      extra: {
        'exam': examToPass,
        'hideCategoryAndGrade': true,
        'hidePoints': false,
        'hideTimer': false,
      },
    );

    if (result != null && mounted) {
      setState(() {
        final idx = _exams.indexWhere((e) => e.id == result.id);
        if (idx != -1) {
          _exams[idx] = result;
        } else {
          _exams.add(result);
        }
      });
      _scheduleAutosave();
    }
  }

  // --- Layout Builders ---

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          LectureExitConfirmationSheet.show(
            context,
            onExitWithoutSaving: () => context.pop(),
            onSaveAsDraft: () async {
              setState(() => _isPublished = false);
              await _handleSave();
            },
            onSaveAndPublish: () async {
              setState(() => _isPublished = true);
              await _handleSave();
            },
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= AppTokens.breakpointTablet;
            if (isDesktop) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.lectureEditorScreen,
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                LectureEditorMobileAppBar(
                  title: _isEditing ? 'تحرير المحاضرة' : 'إضافة محاضرة جديدة',
                  onBack: () => LectureExitConfirmationSheet.show(
                    context,
                    onExitWithoutSaving: () => context.pop(),
                    onSaveAsDraft: () async {
                      setState(() => _isPublished = false);
                      await _handleSave();
                    },
                    onSaveAndPublish: () async {
                      setState(() => _isPublished = true);
                      await _handleSave();
                    },
                  ),
                  onSaveDraft: () async {
                    setState(() => _isPublished = false);
                    await _handleSave();
                  },
                  onPublish: () async {
                    setState(() => _isPublished = true);
                    await _handleSave();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: InsetToggle(
                    value: !_isMobileContentView,
                    onChanged: (val) => setState(() => _isMobileContentView = !val),
                    labelLeft: 'المحتوى',
                    labelRight: 'الإعدادات',
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: context.watch<PotatoModeProvider>().animationsEnabled
                        ? AppTokens.durationFast
                        : Duration.zero,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                        ),
                        child: child,
                      );
                    },
                    child: _isMobileContentView
                        ? _buildContentTab()
                        : _buildMobileSettingsTab(),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _isMobileContentView
            ? FloatingActionButton(
                key: TestKeys.lectureEditorAddBlock,
                onPressed: () => AddContentSheet.show(
                  context,
                  onAddText: () => TextBlockEditorSheet.show(context, onSave: _onContentBlockSaved),
                  onAddYoutube: () => YoutubeLinkEditorSheet.show(context, onSave: _onContentBlockSaved),
                  onAddQuiz: () => _showExamEditor(isQuiz: true),
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  Widget _buildMobileSettingsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSettingsFields(),
                  const SizedBox(height: AppTokens.spacing24),
                  const Divider(height: 1),
                  const SizedBox(height: AppTokens.spacing24),
                  _buildExamsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setState(() => _isPublished = false);
                      await _handleSave();
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isPublished ? 'حفظ التعديلات' : 'حفظ كمسودة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.foreground(context),
                      side: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTokens.radiusLgAll,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      setState(() => _isPublished = true);
                      await _handleSave();
                    },
                    icon: Icon(_isPublished ? Icons.check_circle : Icons.publish),
                    label: Text(_isPublished ? 'تم النشر' : 'نشر الآن'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isPublished ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTokens.radiusLgAll,
                      ),
                      elevation: AppTokens.elevationNone,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('عنوان المحاضرة'),
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration('أدخل عنوان المحاضرة...', Icons.title_rounded),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
        ),
        const SizedBox(height: AppTokens.spacing16),
        if (!_hideCategoryAndGrade) ...[
          _buildFieldLabel('القسم'),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: _inputDecoration('اختر القسم', Icons.category_rounded),
            items: CategoryMetadata.categories.map((cat) {
              return DropdownMenuItem(
                value: cat.id,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color, size: 18),
                    const SizedBox(width: 12),
                    Flexible(child: Text(cat.name, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategoryId = val);
            },
          ),
          const SizedBox(height: AppTokens.spacing16),
          _buildFieldLabel('الصف المستهدف'),
          DropdownButtonFormField<int>(
            initialValue: _selectedGrade,
            decoration: _inputDecoration('اختر الصف', Icons.school_rounded),
            items: const [
              DropdownMenuItem(value: 1, child: Text('الأول الثانوية')),
              DropdownMenuItem(value: 2, child: Text('الثاني الثانوية')),
              DropdownMenuItem(value: 3, child: Text('الثالث الثانوية')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedGrade = val);
            },
          ),
          const SizedBox(height: AppTokens.spacing16),
        ],
        _buildFieldLabel('ترتيب العرض'),
        TextFormField(
          controller: _sortOrderController,
          decoration: _inputDecoration('ترتيب العرض', Icons.sort_rounded),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
              return 'يجب أن يكون رقمًا';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTokens.spacing16),
        SwitchListTile(
          title: const Text('نشر المحاضرة'),
          subtitle: const Text('تفعيل هذا الخيار يجعل المحاضرة مرئية للطلاب مباشرة'),
          value: _isPublished,
          onChanged: (val) {
            setState(() => _isPublished = val);
            _scheduleAutosave();
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppTokens.spacing8),
        Container(
          padding: const EdgeInsets.all(AppTokens.spacing6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: AppTokens.radiusMdAll,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: AppTokens.spacing4),
              Expanded(
                child: Text(
                  'سيتم اشتقاق الحقول القديمة (رابط الفيديو، الوصف، الاختبار) تلقائياً من الكتلة الأولى من كل نوع عند الحفظ',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeSm,
                    color: AppColors.mutedColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_lastAutosaveAt != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacing4),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  size: 16,
                  color: AppColors.mutedColor(context),
                ),
                const SizedBox(width: AppTokens.spacing2),
                Text(
                  'تم الحفظ تلقائياً · ${_lastAutosaveAt!.hour.toString().padLeft(2, '0')}:${_lastAutosaveAt!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeXs,
                    color: AppColors.mutedColor(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool get _hideCategoryAndGrade => false;

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, right: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTokens.fontSizeMd,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground(context).withValues(alpha: 0.8),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
      filled: true,
      fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
      border: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // --- Desktop Layout ---

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.lectureEditorScreen,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: LectureEditorDesktopLayout(
              isDark: isDark,
              activeSidebarIndex: _activeSidebarIndex,
              onSidebarIndexChanged: (i) => setState(() => _activeSidebarIndex = i),
              onSaveDraft: () async {
                setState(() => _isPublished = false);
                await _handleSave();
              },
              onPublish: () async {
                setState(() => _isPublished = true);
                await _handleSave();
              },
              onExit: () => LectureExitConfirmationSheet.show(
                context,
                onExitWithoutSaving: () => context.pop(),
                onSaveAsDraft: () async {
                  setState(() => _isPublished = false);
                  await _handleSave();
                },
                onSaveAndPublish: () async {
                  setState(() => _isPublished = true);
                  await _handleSave();
                },
              ),
              buildContentTab: _buildContentTab,
              buildExamsTab: _buildDesktopExamsTab,
              buildSettingsTab: _buildDesktopSettingsTab,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSettingsTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'تعديل المحاضرة' : 'إعدادات المحاضرة',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                fontFamily: AppTokens.fontFamilyDisplay,
                color: AppColors.foreground(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacing24),
            _buildSettingsFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopExamsTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الامتحانات الختامية',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                fontFamily: AppTokens.fontFamilyDisplay,
                color: AppColors.foreground(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacing16),
            _buildExamsSection(),
          ],
        ),
      ),
    );
  }

  // --- Shared Sections ---

  Widget _buildExamsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_exams.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
              borderRadius: AppTokens.radiusMdAll,
            ),
            child: Column(
              children: [
                Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'لا توجد امتحانات ختامية مضافة',
                  style: TextStyle(color: AppColors.mutedColor(context)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showExamsTabEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة امتحان'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          )
        else
          ..._exams.map((exam) {
            final qCount = exam.questions.length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232527) : Colors.white,
                borderRadius: AppTokens.radiusMdAll,
                boxShadow: AppTokens.shadowOutside,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppTokens.radiusMdAll,
                child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  exam.durationMinutes != null
                      ? '$qCount سؤال · ${exam.durationMinutes} دقيقة'
                      : '$qCount سؤال',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                      onPressed: () => _showExamsTabEditor(existingExam: exam),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey.shade400, size: 20),
                      onPressed: () {
                        setState(() {
                          _exams.remove(exam);
                        });
                        _scheduleAutosave();
                      },
                    ),
                  ],
                ),
              ),
              ),
            );
          }),
        if (_exams.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showExamsTabEditor(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة امتحان إضافي'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  // --- Tab Builders ---

  Widget _buildContentTab() {
    final isDesktop = AppTokens.isDesktop(context);

    if (_contentBlocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'ما من محتوى بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => TextBlockEditorSheet.show(context, onSave: _onContentBlockSaved),
              child: const Text(
                'إضافة نص',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.article, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'محتوى المحاضرة',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeXl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground(context),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => AddContentSheet.show(
                    context,
                    onAddText: () => TextBlockEditorSheet.show(context, onSave: _onContentBlockSaved),
                    onAddYoutube: () => YoutubeLinkEditorSheet.show(context, onSave: _onContentBlockSaved),
                    onAddQuiz: () => _showExamEditor(isQuiz: true),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة عنصر'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            itemCount: _contentBlocks.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _contentBlocks.removeAt(oldIndex);
                _contentBlocks.insert(newIndex, item);
              });
              _scheduleAutosave();
            },
            itemBuilder: (context, index) {
              final block = _contentBlocks[index];
              return BlockRowWidget(
                key: ValueKey(block.id),
                index: index,
                icon: _getBlockIcon(block.type),
                title: _getBlockTitle(block),
                subtitle: _getBlockSubtitle(block),
                badge: _getBlockBadge(block),
                onAction: (action) => _handleBlockAction(action, block, index),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getBlockIcon(BlockType type) {
    switch (type) {
      case BlockType.text:
        return Icons.text_snippet;
      case BlockType.youtube:
        return Icons.play_circle_outline;
      case BlockType.exam:
      case BlockType.quiz:
        return Icons.quiz_outlined;
    }
  }

  String _getBlockTitle(LectureContentBlock block) {
    switch (block.type) {
      case BlockType.text:
        return 'محتوى نصي مقروء';
      case BlockType.youtube:
        return 'مقطع فيديو يوتيوب';
      case BlockType.exam:
      case BlockType.quiz:
        return block.metadata?['title'] ?? 'اختبار قصير (امتحن)';
    }
  }

  String _getBlockSubtitle(LectureContentBlock block) {
    switch (block.type) {
      case BlockType.text:
        return block.content;
      case BlockType.youtube:
        return block.content;
      case BlockType.exam:
      case BlockType.quiz:
        final qCount = block.metadata?['questionsCount'] ?? 0;
        return 'اختبار مرتبط - يحتوي على $qCount أسئلة';
    }
  }

  String? _getBlockBadge(LectureContentBlock block) {
    switch (block.type) {
      case BlockType.text:
        return '~${(block.content.length / 180).ceil()} د قراءة';
      case BlockType.youtube:
        final duration = block.metadata?['duration']?.toString() ?? '';
        return duration.isEmpty ? null : duration;
      case BlockType.exam:
      case BlockType.quiz:
        return '${block.metadata?['questionsCount'] ?? 0} سؤال';
    }
  }

  void _handleBlockAction(
    BlockRowAction action,
    LectureContentBlock block,
    int index,
  ) {
    switch (action) {
      case BlockRowAction.edit:
        if (block.type == BlockType.text) {
          TextBlockEditorSheet.show(context, existingBlock: block, index: index, onSave: _onContentBlockSaved);
        } else if (block.type == BlockType.youtube) {
          YoutubeLinkEditorSheet.show(context, existingBlock: block, index: index, onSave: _onContentBlockSaved);
        } else {
          _showExamEditor(existingBlock: block, index: index, isQuiz: true);
        }
      case BlockRowAction.preview:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: SingleChildScrollView(
                child: BlockPreviewWidget(
                  block: block,
                  onEdit: (block.type == BlockType.quiz || block.type == BlockType.exam)
                      ? () => _showExamEditor(existingBlock: block, isQuiz: true)
                      : null,
                ),
              ),
            ),
          ),
        );
      case BlockRowAction.delete:
        setState(() {
          _contentBlocks.removeAt(index);
        });
        _scheduleAutosave();
    }
  }
}
