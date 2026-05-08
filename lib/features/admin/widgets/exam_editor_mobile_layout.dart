import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_state.dart';
import 'package:arabilogia/features/admin/widgets/inset_toggle.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_panel.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_action_buttons.dart';
import 'package:arabilogia/features/admin/widgets/question_list_panel.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_mobile_app_bar.dart';

class ExamEditorMobileLayout extends StatelessWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onExit;
  final VoidCallback onCancel;
  final void Function(String, String, [String]) onAddPassage;
  final void Function(int) onDeletePassage;

  const ExamEditorMobileLayout({
    super.key,
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          body: SafeArea(
            child: Column(
              children: [
                ExamEditorMobileAppBar(
                  title: state.title,
                  onBack: onExit,
                  onSaveDraft: onSaveDraft,
                  onPublish: onPublish,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: InsetToggle(
                    value: state.isMobileSettingsMode,
                    onChanged: (val) => state.setMobileSettingsMode(val),
                    labelLeft: 'الاسئلة',
                    labelRight: 'إعدادات',
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: context.watch<PotatoModeProvider>().animationsEnabled ? AppTokens.durationFast : Duration.zero,
                    child: !state.isMobileSettingsMode
                        ? QuestionListPanel(
                            questions: state.questions,
                            questionSettings: state.questionSettings,
                            passages: state.passages,
                            getPassageValue: state.getPassageValue,
                            getPassageContent: state.getPassageContent,
                            isSavedPassage: state.isSavedPassage,
                            isMobile: true,
                            onAddQuestion: state.addNewQuestion,
                            onDeleteQuestion: state.deleteQuestion,
                            onDuplicateQuestion: state.duplicateQuestion,
                            onUpdateQuestion: state.updateQuestion,
                            onUpdateSettings: state.updateQuestionSettings,
                            onReorderQuestions: state.reorderQuestions,
                          )
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
                                onAddPassage: onAddPassage,
                                onDeletePassage: onDeletePassage,
                                onCancel: onCancel,
                                onSaveDraft: onSaveDraft,
                                onPublish: onPublish,
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
                                    onSaveDraft: onSaveDraft,
                                    onPublish: onPublish,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: !state.isMobileSettingsMode
              ? FloatingActionButton(
                  onPressed: state.addNewQuestion,
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
}
