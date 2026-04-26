import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final List<Map<String, String>> passages;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final bool Function(String?) isSavedPassage;
  final bool isMobile;
  final VoidCallback onDelete;
  final Function(Question) onUpdate;

  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.passages,
    required this.getPassageValue,
    required this.getPassageContent,
    required this.isSavedPassage,
    this.isMobile = false,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppTokens.spacing24),
        padding: const EdgeInsets.all(AppTokens.spacing20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: _buildCardContent(context, isDark),
      );
    }
    return GlassContainer(
      isMobile: isMobile,
      padding: const EdgeInsets.all(AppTokens.spacing24),
      child: _buildCardContent(context, isDark),
    );
  }

  Widget _buildCardContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تفاصيل السؤال',
              style: TextStyle(
                fontSize: AppTokens.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'حذف السؤال',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing24),
        if (passages.isNotEmpty) ...[
          _buildPassageDropdown(context, isDark),
          const SizedBox(height: 12),
        ],
        _buildPassageTextField(context, isDark),
        const SizedBox(height: AppTokens.spacing24),
        _buildFieldLabel('نص السؤال', context),
        TextFormField(
          initialValue: question.text,
          maxLines: 2,
          decoration: _inputDecoration(
            'ما هو السؤال؟',
            Icons.help_outline,
            isDark,
          ),
          onChanged: (val) => onUpdate(_copyWithQuestion(question, text: val)),
        ),
        const SizedBox(height: AppTokens.spacing32),
        _buildFieldLabel('خيارات الإجابة (حدد الإجابة الصحيحة)', context),
        const SizedBox(height: AppTokens.spacing12),
        _buildOptionsGrid(context, isDark),
      ],
    );
  }

  Widget _buildFieldLabel(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTokens.fontSizeMd,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedColor(context),
        ),
      ),
    );
  }

  Widget _buildPassageDropdown(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('المقرو�� (اختياري)', context),
        DropdownButtonFormField<String>(
          value: getPassageValue(question.passage),
          decoration: _inputDecoration(
            'اختر مقروء أو أكتب جديد',
            Icons.book_outlined,
            isDark,
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('-- بدون مقروء --')),
            ...passages.map(
              (p) => DropdownMenuItem(
                value: p['id'],
                child: Text(
                  p['title'] ?? 'بدون عنوان',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const DropdownMenuItem(
              value: '__custom__',
              child: Text('+ كتابة مقروء جديد'),
            ),
          ],
          onChanged: (val) {
            if (val == null || val.isEmpty) {
              onUpdate(_copyWithQuestion(question, passage: null));
            } else if (val == '__custom__') {
              onUpdate(_copyWithQuestion(question, passage: ''));
            } else {
              final content = getPassageContent(val);
              onUpdate(_copyWithQuestion(question, passage: content));
            }
          },
        ),
      ],
    );
  }

  Widget _buildPassageTextField(BuildContext context, bool isDark) {
    final passageId = getPassageValue(question.passage);
    final isWithoutPassage =
        passageId == '' &&
        (question.passage == null || question.passage!.isEmpty);
    final savedPassage = isSavedPassage(passageId);
    if (isWithoutPassage) return const SizedBox.shrink();
    final bgColor = savedPassage
        ? (isDark
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.05))
        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03));
    return TextFormField(
      initialValue: question.passage,
      maxLines: 4,
      readOnly: savedPassage,
      style: savedPassage
          ? TextStyle(
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
            )
          : null,
      decoration: InputDecoration(
        hintText: savedPassage
            ? 'هذا المقروء مرتبط من المقروءات (readonly)'
            : 'أدخل نص الفقرة أو المقتطف الذي يبنى عليه السؤال...',
        prefixIcon: const Icon(Icons.article_outlined),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: AppTokens.radiusMdAll,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      onChanged: savedPassage
          ? null
          : (val) => onUpdate(
              _copyWithQuestion(question, passage: val.isEmpty ? null : val),
            ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, optIndex) => _buildOptionItem(optIndex, isDark),
    );
  }

  Widget _buildOptionItem(int optIndex, bool isDark) {
    final option = optIndex < question.options.length
        ? question.options[optIndex]
        : Option(id: 'o${optIndex + 1}', text: '', isCorrect: false);
    final isCorrect = option.isCorrect;
    final correctIdx = question.options.indexWhere((o) => o.isCorrect);
    return AnimatedContainer(
      duration: AppTokens.durationFast,
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: AppTokens.radiusMdAll,
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.grey.withValues(alpha: 0.2),
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Radio<int>(
            value: optIndex,
            groupValue: correctIdx >= 0 ? correctIdx : null,
            activeColor: Colors.green,
            onChanged: (val) {
              if (val != null) {
                final updatedOpts = <Option>[];
                for (int i = 0; i < question.options.length; i++) {
                  updatedOpts.add(
                    Option(
                      id: question.options[i].id,
                      text: question.options[i].text,
                      isCorrect: i == val,
                    ),
                  );
                }
                onUpdate(_copyWithQuestion(question, options: updatedOpts));
              }
            },
          ),
          Expanded(
            child: TextFormField(
              initialValue: option.text,
              style: const TextStyle(fontSize: AppTokens.fontSizeMd),
              decoration: const InputDecoration(
                hintText: 'الخيار...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (val) {
                final updatedOpts = <Option>[];
                for (int i = 0; i < question.options.length; i++) {
                  updatedOpts.add(
                    Option(
                      id: question.options[i].id,
                      text: i == optIndex ? val : question.options[i].text,
                      isCorrect: question.options[i].isCorrect,
                    ),
                  );
                }
                onUpdate(_copyWithQuestion(question, options: updatedOpts));
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Question _copyWithQuestion(
    Question q, {
    String? id,
    String? text,
    String? passage,
    List<Option>? options,
  }) {
    return Question(
      id: id ?? q.id,
      text: text ?? q.text,
      passage: passage ?? q.passage,
      options: options ?? q.options,
    );
  }
}
