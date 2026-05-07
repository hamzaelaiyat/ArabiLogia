import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_panel.dart';
import 'package:arabilogia/features/admin/widgets/question_list_panel.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_state.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_preview_overlay.dart';
import 'package:arabilogia/features/admin/widgets/inset_toggle.dart';
import 'package:arabilogia/features/admin/widgets/sub_sidebar.dart';
import 'package:arabilogia/features/admin/widgets/passage_manager.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_action_buttons.dart';

class ExamEditor extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        if (existingExam != null) {
          return ExamEditorState.fromExam(existingExam!);
        } else {
          return ExamEditorState.empty();
        }
      },
      child: _ExamEditorContent(
        onSave: onSave,
        onCancel: onCancel,
      ),
    );
  }
}

class _ExamEditorContent extends StatefulWidget {
  final Function(Exam) onSave;
  final VoidCallback onCancel;

  const _ExamEditorContent({
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ExamEditorContent> createState() => _ExamEditorContentState();
}

class _ExamEditorContentState extends State<_ExamEditorContent> with TickerProviderStateMixin {
  final PageController _questionPageController = PageController();
  late TabController _tabController;
  bool _isPreviewOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB visibility
    });
  }

  @override
  void dispose() {
    _questionPageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addNewQuestion() {
    context.read<ExamEditorState>().addNewQuestion();
  }

  void _deleteQuestion(int index) {
    context.read<ExamEditorState>().deleteQuestion(index);
  }

  void _duplicateQuestion(int index) {
    context.read<ExamEditorState>().duplicateQuestion(index);
  }

  void _updateQuestion(int index, Question question) {
    context.read<ExamEditorState>().updateQuestion(index, question);
  }

  void _updateQuestionSettings(int index, QuestionSettings? settings) {
    context.read<ExamEditorState>().updateQuestionSettings(index, settings);
  }

  void _addPassage(String title, String content) {
    context.read<ExamEditorState>().addPassage(title, content);
  }

  void _deletePassage(int index) {
    context.read<ExamEditorState>().deletePassage(index);
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    context.read<ExamEditorState>().reorderQuestions(oldIndex, newIndex);
  }

  void _saveExam({bool publish = false}) {
    final state = context.read<ExamEditorState>();
    final validation = state.validate();
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.errorMessage!)),
      );
      return;
    }
    widget.onSave(state.toExam(publish: publish));
  }

  void _togglePreview() {
    setState(() {
      _isPreviewOpen = !_isPreviewOpen;
    });
    context.read<ExamEditorState>().setShowPreview(_isPreviewOpen);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.background(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppTokens.breakpointTablet;

        final content = isDesktop
            ? _buildDesktopLayout(isDark, bgColor)
            : _buildMobileLayout(bgColor);

        return Consumer<ExamEditorState>(
          builder: (context, state, _) {
            return Stack(
              children: [
                content,
                ExamPreviewOverlay(
                  isVisible: state.showPreview,
                  isDesktop: isDesktop,
                  questions: state.questions,
                  questionSettings: state.questionSettings,
                  onClose: _togglePreview,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout(bool isDark, Color bgColor) {
    return Consumer<ExamEditorState>(
      builder: (context, state, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar Container (Right side now)
            Container(
              width: 400,
              color: isDark ? const Color(0xFF191B1D) : const Color(0xFFF7FCFF),
              child: Row(
                children: [
                  SubSidebar(
                    activeIndex: state.activeSidebarIndex,
                    onIndexChanged: (index) => state.setActiveSidebarIndex(index),
                    onSave: () => _saveExam(publish: false),
                    onPublish: () => _saveExam(publish: true),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppTokens.durationFast,
                      child: state.activeSidebarIndex == 0
                          ? ExamSettingsPanel(
                              key: const ValueKey('settings'),
                              title: state.title,
                              selectedCategoryId: state.selectedCategoryId,
                              selectedGrade: state.selectedGrade,
                              durationMinutes: state.durationMinutes,
                              durationEnabled: state.durationEnabled,
                              isPublished: state.isPublished,
                              passages: state.passages,
                              onTitleChanged: (v) => state.title = v,
                              onCategoryChanged: (v) => state.selectedCategoryId = v,
                              onGradeChanged: (v) => state.selectedGrade = v,
                              onDurationChanged: (v) => state.durationMinutes = v,
                              onDurationToggle: (v) => state.durationEnabled = v,
                              onAddPassage: _addPassage,
                              onDeletePassage: _deletePassage,
                              onCancel: widget.onCancel,
                              onSaveDraft: () => _saveExam(publish: false),
                              onPublish: () => _saveExam(publish: true),
                              onPreview: _togglePreview,
                            )
                          : Padding(
                              key: const ValueKey('passages'),
                              padding: const EdgeInsets.all(AppTokens.spacing24),
                              child: PassageManager(
                                passages: state.passages,
                                onAddPassage: _addPassage,
                                onDeletePassage: _deletePassage,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
            // Question List Panel (Left side now)
            Expanded(
              flex: 3,
              child: _buildQuestionListPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout(Color bgColor) {
    return Consumer<ExamEditorState>(
      builder: (context, state, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: InsetToggle(
                  value: state.isMobileSettingsMode,
                  onChanged: (val) => state.setMobileSettingsMode(val),
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: AppTokens.durationFast,
            child: !state.isMobileSettingsMode
                ? _buildQuestionListPanel(isMobile: true)
                : Stack(
                    children: [
                      ExamSettingsPanel(
                        title: state.title,
                        selectedCategoryId: state.selectedCategoryId,
                        selectedGrade: state.selectedGrade,
                        durationMinutes: state.durationMinutes,
                        durationEnabled: state.durationEnabled,
                        isPublished: state.isPublished,
                        passages: state.passages,
                        isMobile: true,
                        onTitleChanged: (v) => state.title = v,
                        onCategoryChanged: (v) => state.selectedCategoryId = v,
                        onGradeChanged: (v) => state.selectedGrade = v,
                        onDurationChanged: (v) => state.durationMinutes = v,
                        onDurationToggle: (v) => state.durationEnabled = v,
                        onAddPassage: _addPassage,
                        onDeletePassage: _deletePassage,
                        onCancel: widget.onCancel,
                        onSaveDraft: () => _saveExam(publish: false),
                        onPublish: () => _saveExam(publish: true),
                        onPreview: _togglePreview,
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
                          child: ExamSettingsActionButtons(
                            isPublished: state.isPublished,
                            onSaveDraft: () => _saveExam(publish: false),
                            onPublish: () => _saveExam(publish: true),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          floatingActionButton: !state.isMobileSettingsMode
              ? FloatingActionButton(
                  onPressed: _addNewQuestion,
                  backgroundColor: AppColors.primary,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTokens.radiusFullAll,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        );
      },
    );
  }

  Widget _buildQuestionListPanel({bool isMobile = false}) {
    return Consumer<ExamEditorState>(
      builder: (context, state, _) {
        return QuestionListPanel(
          questions: state.questions,
          questionSettings: state.questionSettings,
          passages: state.passages,
          getPassageValue: state.getPassageValue,
          getPassageContent: state.getPassageContent,
          isSavedPassage: state.isSavedPassage,
          isMobile: isMobile,
          onAddQuestion: _addNewQuestion,
          onDeleteQuestion: _deleteQuestion,
          onDuplicateQuestion: _duplicateQuestion,
          onUpdateQuestion: _updateQuestion,
          onUpdateSettings: _updateQuestionSettings,
          onReorderQuestions: _reorderQuestions,
        );
      },
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}