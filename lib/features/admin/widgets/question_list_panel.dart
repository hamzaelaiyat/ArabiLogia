import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/question_card.dart';
import 'package:arabilogia/features/admin/widgets/question_list_header.dart';
import 'package:arabilogia/features/admin/widgets/question_list_empty.dart';
import 'package:arabilogia/features/admin/widgets/question_list_add_button.dart';

class QuestionListPanel extends StatelessWidget {
  final List<Question> questions;
  final List<QuestionSettings> questionSettings;
  final List<Map<String, String>> passages;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final bool Function(String?) isSavedPassage;
  final bool isMobile;
  final VoidCallback onAddQuestion;
  final Function(int) onDeleteQuestion;
  final Function(int) onDuplicateQuestion;
  final Function(int, Question) onUpdateQuestion;
  final Function(int, QuestionSettings?) onUpdateSettings;
  final Function(int, int)? onReorderQuestions;

  const QuestionListPanel({
    super.key,
    required this.questions,
    required this.questionSettings,
    required this.passages,
    required this.getPassageValue,
    required this.getPassageContent,
    required this.isSavedPassage,
    this.isMobile = false,
    required this.onAddQuestion,
    required this.onDeleteQuestion,
    required this.onDuplicateQuestion,
    required this.onUpdateQuestion,
    required this.onUpdateSettings,
    this.onReorderQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          QuestionListHeader(
            questionCount: questions.length,
            isMobile: isMobile,
          ),
          Expanded(
            child: questions.isEmpty
                ? QuestionListEmpty(onAddQuestion: onAddQuestion)
                : onReorderQuestions != null
                    ? _buildReorderableList()
                    : _buildRegularList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
                vertical: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
              ),
              itemCount: questions.length + 1,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < questions.length && newIndex <= questions.length) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  onReorderQuestions!(oldIndex, newIndex);
                }
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 8,
                  color: Colors.transparent,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                if (index == questions.length) {
                  if (isMobile) return SizedBox.shrink(key: ValueKey('add_question_placeholder_$index'));
                  return Padding(
                    key: const ValueKey('add_question_button'),
                    padding: EdgeInsets.only(
                      top: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
                      bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing32,
                    ),
                    child: QuestionListAddButton(onPressed: onAddQuestion),
                  );
                }
                return TweenAnimationBuilder<double>(
                  key: ValueKey(questions[index].id),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppTokens.durationMd,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing24,
                    ),
                    child: QuestionCard(
                      key: ValueKey(questions[index].id),
                      question: questions[index],
                      settings: index < questionSettings.length ? questionSettings[index] : null,
                      index: index,
                      passages: passages,
                      getPassageValue: getPassageValue,
                      getPassageContent: getPassageContent,
                      isSavedPassage: isSavedPassage,
                      isMobile: isMobile,
                      onDelete: () => onDeleteQuestion(index),
                      onDuplicate: () => onDuplicateQuestion(index),
                      onUpdate: (q) => onUpdateQuestion(index, q),
                      onSettingsUpdate: (s) => onUpdateSettings(index, s),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegularList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTokens.spacing12 : AppTokens.spacing32,
        vertical: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
      ),
      itemCount: questions.length + 1,
      itemBuilder: (context, index) {
        if (index == questions.length) {
          if (isMobile) return SizedBox.shrink(key: ValueKey('add_question_placeholder_reg_$index'));
          return Padding(
            padding: EdgeInsets.only(
              top: isMobile ? AppTokens.spacing8 : AppTokens.spacing16,
              bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing32,
            ),
            child: QuestionListAddButton(onPressed: onAddQuestion),
          );
        }
        return TweenAnimationBuilder<double>(
          key: ValueKey(questions[index].id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppTokens.durationMd,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isMobile ? AppTokens.spacing8 : AppTokens.spacing32,
            ),
            child: QuestionCard(
              key: ValueKey(questions[index].id),
              question: questions[index],
              settings: index < questionSettings.length ? questionSettings[index] : null,
              index: index,
              passages: passages,
              getPassageValue: getPassageValue,
              getPassageContent: getPassageContent,
              isSavedPassage: isSavedPassage,
              isMobile: isMobile,
              onDelete: () => onDeleteQuestion(index),
              onDuplicate: () => onDuplicateQuestion(index),
              onUpdate: (q) => onUpdateQuestion(index, q),
              onSettingsUpdate: (s) => onUpdateSettings(index, s),
            ),
          ),
        );
      },
    );
  }

}