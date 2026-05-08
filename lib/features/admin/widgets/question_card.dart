import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/question_input.dart';
import 'package:arabilogia/features/admin/widgets/question_header_actions.dart';
import 'package:arabilogia/features/admin/widgets/question_passage_selector.dart';
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
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final Function(Question) onUpdate;
  final Function(QuestionSettings)? onSettingsUpdate;

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
    required this.onDelete,
    required this.onDuplicate,
    required this.onUpdate,
    this.onSettingsUpdate,
  })  : getPassageValue = getPassageValue ?? _defaultGetPassageValue,
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
          _optionControllers[i].selection = TextSelection.collapsed(offset: optionText.length);
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
    final currentPoints = widget.settings?.points.points ?? 10;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? AppTokens.spacing12 : AppTokens.spacing24),
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
                    onPreview: () => _showQuestionPreview(context),
                    onDuplicate: widget.onDuplicate,
                    onDelete: widget.onDelete,
                    onPointsTap: () => _showPointsEditing(context, currentPoints),
                  ),
                ),
                ReorderableDragStartListener(
                  index: widget.index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: isDark ? Colors.white38 : Colors.black26,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
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
            QuestionPassageSelector(
              passages: widget.passages,
              getPassageValue: widget.getPassageValue,
              getPassageContent: widget.getPassageContent,
              passageQuestionRef: widget.question.passage,
              onPassageChanged: (val) {
                widget.onUpdate(widget.question.copyWith(passage: val));
              },
            ),
          if (widget.passages.isNotEmpty) const SizedBox(height: 12),
          QuestionInput(
            key: _inputKey,
            value: widget.question.text,
            hint: 'ما هو السؤال؟',
            onChanged: (val) => widget.onUpdate(widget.question.copyWith(text: val)),
          ),
        ],
      ),
    );
  }

  void _updateOptionText(int optIndex, String val) {
    final newOptions = List<Option>.from(widget.question.options);
    while (newOptions.length <= optIndex) {
      newOptions.add(Option(id: 'opt_${newOptions.length}', text: '', isCorrect: false));
    }
    newOptions[optIndex] = newOptions[optIndex].copyWith(text: val);
    widget.onUpdate(widget.question.copyWith(options: newOptions));
  }

  void _toggleCorrectAnswer(int optIndex) {
    final newOptions = List<Option>.from(widget.question.options);
    while (newOptions.length < 4) {
      newOptions.add(Option(id: 'opt_${newOptions.length}', text: '', isCorrect: false));
    }
    final wasCorrect = newOptions[optIndex].isCorrect;
    newOptions[optIndex] = newOptions[optIndex].copyWith(isCorrect: !wasCorrect);
    widget.onUpdate(widget.question.copyWith(options: newOptions));
  }

  void _showPointsEditing(BuildContext context, int currentPoints) {
    final isMobile = MediaQuery.of(context).size.width < AppTokens.breakpointTablet;
    if (isMobile) {
      QuestionPointsDialogs.showSheet(context, currentPoints, _applyPoints);
    } else {
      QuestionPointsDialogs.showDesktopDialog(context, currentPoints, _applyPoints);
    }
  }

  void _applyPoints(int points) {
    final newSettings = (widget.settings ?? const QuestionSettings()).copyWith(
      points: QuestionPoints(points: points),
    );
    widget.onSettingsUpdate?.call(newSettings);
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
