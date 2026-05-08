import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_state.dart';
import 'package:arabilogia/features/admin/widgets/sub_sidebar.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_panel.dart';
import 'package:arabilogia/features/admin/widgets/passage_manager.dart';
import 'package:arabilogia/features/admin/widgets/question_list_panel.dart';

class ExamEditorDesktopLayout extends StatelessWidget {
  final bool isDark;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onExit;
  final VoidCallback onCancel;
  final void Function(String, String, [String]) onAddPassage;
  final void Function(int) onDeletePassage;

  const ExamEditorDesktopLayout({
    super.key,
    required this.isDark,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onExit,
    required this.onCancel,
    required this.onAddPassage,
    required this.onDeletePassage,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamEditorState>(
      builder: (context, state, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 400,
              color: isDark ? const Color(0xFF191B1D) : const Color(0xFFF7FCFF),
              child: Row(
                children: [
                  SubSidebar(
                    activeIndex: state.activeSidebarIndex,
                    onIndexChanged: (index) => state.setActiveSidebarIndex(index),
                    onSave: onSaveDraft,
                    onPublish: onPublish,
                    onExit: onExit,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: context.watch<PotatoModeProvider>().animationsEnabled ? AppTokens.durationFast : Duration.zero,
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
                              onAddPassage: onAddPassage,
                              onDeletePassage: onDeletePassage,
                              onCancel: onCancel,
                              onSaveDraft: onSaveDraft,
                              onPublish: onPublish,
                            )
                          : Padding(
                              key: const ValueKey('passages'),
                              padding: const EdgeInsets.all(AppTokens.spacing24),
                              child: PassageManager(
                                passages: state.passages,
                                onAddPassage: onAddPassage,
                                onDeletePassage: onDeletePassage,
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
            Expanded(
              flex: 3,
              child: QuestionListPanel(
                questions: state.questions,
                questionSettings: state.questionSettings,
                passages: state.passages,
                getPassageValue: state.getPassageValue,
                getPassageContent: state.getPassageContent,
                isSavedPassage: state.isSavedPassage,
                isMobile: false,
                onAddQuestion: state.addNewQuestion,
                onDeleteQuestion: state.deleteQuestion,
                onDuplicateQuestion: state.duplicateQuestion,
                onUpdateQuestion: state.updateQuestion,
                onUpdateSettings: state.updateQuestionSettings,
                onReorderQuestions: state.reorderQuestions,
              ),
            ),
          ],
        );
      },
    );
  }
}
