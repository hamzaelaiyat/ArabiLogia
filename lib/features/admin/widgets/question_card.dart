import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/question_input.dart';
import 'package:arabilogia/features/admin/widgets/question_header_actions.dart';
import 'package:arabilogia/features/admin/widgets/passage_selector.dart';
import 'package:arabilogia/features/admin/widgets/question_options_editor.dart';
import 'package:arabilogia/features/admin/widgets/question_preview_dialog.dart';

class QuestionCard extends StatefulWidget {
  static String? _defaultGetPassageValue(String? value) => null;
  static String? _defaultGetPassageContent(String? value) => null;
  static bool _defaultIsSavedPassage(String? value) => false;

  final Question question;
  final QuestionSettings? settings;
  final int index;
  final List<Map<String, String>> passages;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final bool Function(String?) isSavedPassage;
  final bool isMobile;
  final bool hidePoints;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final Function(Question) onUpdate;
  final Function(QuestionSettings)? onSettingsUpdate;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const QuestionCard({
    super.key,
    required this.question,
    this.settings,
    required this.index,
    this.passages = const [],
    String? Function(String?)? getPassageValue,
    String? Function(String?)? getPassageContent,
    bool Function(String?)? isSavedPassage,
    this.isMobile = false,
    this.hidePoints = false,
    required this.onDelete,
    required this.onDuplicate,
    required this.onUpdate,
    this.onSettingsUpdate,
    this.onMoveUp,
    this.onMoveDown,
  }) : getPassageValue = getPassageValue ?? _defaultGetPassageValue,
       getPassageContent = getPassageContent ?? _defaultGetPassageContent,
       isSavedPassage = isSavedPassage ?? _defaultIsSavedPassage;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  final GlobalKey<QuestionInputState> _inputKey = GlobalKey();
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _optionControllers = List.generate(4, (optIndex) {
      final options = widget.question.options;
      final option = options.length > optIndex ? options[optIndex] : null;
      return TextEditingController(text: option?.text ?? '');
    });
  }

  @override
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question.options != oldWidget.question.options) {
      for (int i = 0; i < 4; i++) {
        final options = widget.question.options;
        final optionText = options.length > i ? options[i].text : '';
        if (_optionControllers[i].text != optionText) {
          _optionControllers[i].text = optionText;
          _optionControllers[i].selection = TextSelection.collapsed(
            offset: optionText.length,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = widget.isMobile;
    final currentPoints = widget.question.points;

    return Container(
      margin: EdgeInsets.only(
        bottom: isMobile ? AppTokens.spacing12 : AppTokens.spacing24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232527) : Colors.white,
        borderRadius: AppTokens.radiusLgAll,
        boxShadow: AppTokens.shadowOutside,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: QuestionHeaderActions(
                    index: widget.index,
                    currentPoints: currentPoints,
                    isDark: isDark,
                    hidePoints: widget.hidePoints,
                    onPreview: () => _showQuestionPreview(context),
                    onDuplicate: widget.onDuplicate,
                    onDelete: widget.onDelete,
                    onPointsTap: () =>
                        _showPointsEditing(context, currentPoints),
                  ),
                ),
                _ReorderArrows(
                  onMoveUp: widget.onMoveUp,
                  onMoveDown: widget.onMoveDown,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spacing16,
              0,
              AppTokens.spacing16,
              AppTokens.spacing16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInsideContent(context, isDark),
                const SizedBox(height: AppTokens.spacing16),
                QuestionOptionsEditor(
                  optionControllers: _optionControllers,
                  options: widget.question.options,
                  isMobile: widget.isMobile,
                  isDark: isDark,
                  onOptionTextChanged: _updateOptionText,
                  onCorrectAnswerToggled: _toggleCorrectAnswer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsideContent(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
        borderRadius: AppTokens.radiusMdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.passages.isNotEmpty)
            PassageSelector(
              passages: widget.passages,
              currentPassage: widget.question.passage,
              getPassageValue: widget.getPassageValue,
              getPassageContent: widget.getPassageContent,
              isSavedPassage: widget.isSavedPassage,
              onChanged: (val) {
                widget.onUpdate(widget.question.copyWith(passage: val));
              },
            ),
          if (widget.passages.isNotEmpty) const SizedBox(height: 12),
          QuestionInput(
            key: _inputKey,
            value: widget.question.text,
            hint: 'ما هو السؤال؟',
            onChanged: (val) =>
                widget.onUpdate(widget.question.copyWith(text: val)),
          ),
        ],
      ),
    );
  }

  void _updateOptionText(int optIndex, String val) {
    final newOptions = List<Option>.from(widget.question.options);
    while (newOptions.length <= optIndex) {
      newOptions.add(
        Option(id: 'opt_${newOptions.length}', text: '', isCorrect: false),
      );
    }
    newOptions[optIndex] = newOptions[optIndex].copyWith(text: val);
    widget.onUpdate(widget.question.copyWith(options: newOptions));
  }

  void _toggleCorrectAnswer(int optIndex) {
    final newOptions = List<Option>.from(widget.question.options);
    while (newOptions.length < 4) {
      newOptions.add(
        Option(id: 'opt_${newOptions.length}', text: '', isCorrect: false),
      );
    }
    final wasCorrect = newOptions[optIndex].isCorrect;
    newOptions[optIndex] = newOptions[optIndex].copyWith(
      isCorrect: !wasCorrect,
    );
    widget.onUpdate(widget.question.copyWith(options: newOptions));
  }

  void _showPointsEditing(BuildContext context, int currentPoints) {
    QuestionPointsDialogs.show(context, currentPoints, _applyPoints);
  }

  void _applyPoints(int points) {
    widget.onUpdate(widget.question.copyWith(points: points));
  }

  void _showQuestionPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);
    QuestionPreviewDialogs.show(
      context: context,
      question: widget.question,
      index: widget.index,
      isDark: isDark,
      fgColor: fgColor,
    );
  }
}

class _ReorderArrows extends StatelessWidget {
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isDark;

  const _ReorderArrows({this.onMoveUp, this.onMoveDown, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white38 : Colors.black38;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(Icons.keyboard_arrow_up_rounded, color, onMoveUp),
        _arrow(Icons.keyboard_arrow_down_rounded, color, onMoveDown),
      ],
    );
  }

  Widget _arrow(IconData icon, Color color, VoidCallback? onTap) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radiusSmAll,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
