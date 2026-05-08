import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/question_style.dart';
import 'package:arabilogia/features/admin/widgets/question_input.dart';
import 'package:arabilogia/features/admin/widgets/question_card_extras.dart';

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
          _buildHeader(isDark, context),
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
                _buildOptionsSection(context, isDark),
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
            _buildPassageSelector(context, isDark),
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

  Widget _buildHeader(bool isDark, BuildContext context) {
    final currentPoints = widget.settings?.points.points ?? 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showQuestionPreview(context),
            icon: Icon(
              Icons.visibility_outlined,
              size: 20,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            tooltip: 'معاينة',
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppTokens.radiusFullAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'سؤال ${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeMd,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 12,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showPointsBottomSheet(context, currentPoints),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$currentPoints نقاط',
                          style: const TextStyle(
                            fontSize: AppTokens.fontSizeSm,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onDuplicate,
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            tooltip: 'نسخ',
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            tooltip: 'حذف',
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
    );
  }

  void _showPointsBottomSheet(BuildContext context, int currentPoints) {
    final controller = TextEditingController(text: currentPoints.toString());
    final isMobile = MediaQuery.of(context).size.width < AppTokens.breakpointTablet;

    if (isMobile) {
      _showPointsBottomSheetMobile(context, currentPoints, controller);
    } else {
      _showPointsDialogDesktop(context, currentPoints, controller);
    }
  }

  void _showPointsBottomSheetMobile(BuildContext context, int currentPoints, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF232527)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'تعديل النقاط',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل عدد النقاط للسؤال (من 0.5 إلى 10)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedColor(context),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0.5 - 10',
                    suffixText: 'نقطة',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (val) => _savePoints(context, val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickPointButton(0.5, controller),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickPointButton(1, controller),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickPointButton(2, controller),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickPointButton(5, controller),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickPointButton(10, controller),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _savePoints(context, controller.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPointsDialogDesktop(BuildContext context, int currentPoints, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232527) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'تعديل النقاط',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'أدخل عدد النقاط للسؤال (من 0.5 إلى 10)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedColor(context),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.5 - 10',
                  suffixText: 'نقطة',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (val) => _savePoints(dialogContext, val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildQuickPointButton(0.5, controller)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickPointButton(1, controller)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickPointButton(2, controller)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickPointButton(5, controller)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickPointButton(10, controller)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _savePoints(dialogContext, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPointButton(double points, TextEditingController controller) {
    return OutlinedButton(
      onPressed: () => controller.text = points.toString(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        '${points.toStringAsFixed(points == points.toInt() ? 0 : 1)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _savePoints(BuildContext context, String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم صحيح')),
      );
      return;
    }

    final clampedPoints = parsed.clamp(0.5, 10.0);
    final intPoints = clampedPoints.round();

    final newSettings = (widget.settings ?? const QuestionSettings()).copyWith(
      points: QuestionPoints(points: intPoints),
    );

    widget.onSettingsUpdate?.call(newSettings);
    Navigator.pop(context);
  }

  void _showQuestionPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);
    final isMobile = MediaQuery.of(context).size.width < AppTokens.breakpointTablet;

    if (isMobile) {
      _showQuestionPreviewMobile(context, isDark, fgColor);
    } else {
      _showQuestionPreviewDesktop(context, isDark, fgColor);
    }
  }

  void _showQuestionPreviewMobile(BuildContext context, bool isDark, Color fgColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232527) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'معاينة السؤال ${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: fgColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          widget.question.text.isEmpty
                              ? 'السؤال يظهر هنا...'
                              : widget.question.text,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الخيارات:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(widget.question.options.length, (optIndex) {
                      final options = widget.question.options;
                      if (optIndex >= options.length) return const SizedBox.shrink();
                      final option = options[optIndex];
                      final labels = ['أ', 'ب', 'ج', 'د'];
                      final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: option.isCorrect
                                    ? const Color(0xFF4CAF50)
                                    : (isDark ? Colors.white10 : Colors.black12),
                              ),
                              child: option.isCorrect
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : Center(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white38 : Colors.black26,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text.isEmpty ? 'الخيار $label' : option.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: option.text.isEmpty
                                      ? AppColors.mutedColor(context)
                                      : fgColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionPreviewDesktop(BuildContext context, bool isDark, Color fgColor) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          height: 500,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232527) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'معاينة السؤال ${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: Icon(Icons.close, color: fgColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 16, height: 1.6),
                              children: parseQuestionText(
                                widget.question.text.isEmpty
                                    ? 'السؤال يظهر هنا...'
                                    : widget.question.text,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'الخيارات:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(widget.question.options.length, (optIndex) {
                        final options = widget.question.options;
                        if (optIndex >= options.length) return const SizedBox.shrink();
                        final option = options[optIndex];
                        final labels = ['أ', 'ب', 'ج', 'د'];
                        final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: option.isCorrect
                                      ? const Color(0xFF4CAF50)
                                      : (isDark ? Colors.white10 : Colors.black12),
                                ),
                                child: option.isCorrect
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white38 : Colors.black26,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: option.text.isEmpty
                                          ? AppColors.mutedColor(context)
                                          : fgColor,
                                    ),
                                    children: parseQuestionText(
                                      option.text.isEmpty ? 'الخيار $label' : option.text,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPassageSelector(BuildContext context, bool isDark) {
    final currentPassageId = widget.getPassageValue(widget.question.passage);
    final hasExistingPassage = widget.question.passage?.isNotEmpty == true;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppTokens.radiusMdAll,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (currentPassageId?.isEmpty == true) ? null : currentPassageId,
          hint: Text(
            'اختر فقرة',
            style: TextStyle(
              fontSize: AppTokens.fontSizeSm,
              color: AppColors.mutedColor(context),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('بدون فقرة')),
            ...widget.passages.map(
              (p) => DropdownMenuItem<String>(
                value: p['id'],
                child: Text(
                  p['title'] ?? 'فقرة',
                  style: const TextStyle(fontSize: AppTokens.fontSizeSm),
                ),
              ),
            ),
          ],
          onChanged: (val) {
            widget.onUpdate(widget.question.copyWith(passage: widget.getPassageContent(val)));
          },
        ),
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context, bool isDark) {
    if (widget.isMobile) {
      return _buildMobileOptionsSection(context, isDark);
    }
    return _buildDesktopOptionsSection(context, isDark);
  }

  Widget _buildMobileOptionsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(4, (optIndex) => _buildMobileOptionRow(optIndex, isDark, context)),
      ],
    );
  }

  Widget _buildMobileOptionRow(int optIndex, bool isDark, BuildContext context) {
    final labels = ['أ', 'ب', 'ج', 'د'];
    final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';
    final options = widget.question.options;
    final option = options.length > optIndex ? options[optIndex] : null;
    final isCorrect = option?.isCorrect ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleCorrectAnswer(optIndex),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect
                    ? const Color(0xFF4CAF50)
                    : (isDark ? Colors.white10 : Colors.black12),
              ),
              child: isCorrect
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _optionControllers[optIndex],
              onChanged: (val) => _updateOptionText(optIndex, val),
              maxLines: null,
              minLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'الخيار $label',
                hintStyle: TextStyle(color: AppColors.mutedColor(context)),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopOptionsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حدد أ ب ج أو د',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedColor(context),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(4, (optIndex) => _buildOptionRow(optIndex, isDark, context)),
      ],
    );
  }

  Widget _buildOptionRow(int optIndex, bool isDark, BuildContext context) {
    final labels = ['أ', 'ب', 'ج', 'د'];
    final label = optIndex < labels.length ? labels[optIndex] : '${optIndex + 1}';
    final options = widget.question.options;
    final option = options.length > optIndex ? options[optIndex] : null;
    final isCorrect = option?.isCorrect ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkmark (Inside)
          GestureDetector(
            onTap: () => _toggleCorrectAnswer(optIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect
                    ? const Color(0xFF4CAF50)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              ),
              child: isCorrect
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Input (Inside look)
          Expanded(
            child: TextField(
              controller: _optionControllers[optIndex],
              onChanged: (val) => _updateOptionText(optIndex, val),
              maxLines: null,
              minLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل الخيار $label...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedColor(context).withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
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
}