import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'سؤال',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedColor(context),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'حذف السؤال',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacing16),

          // Question text input with underline
          _buildUnderlineInput(
            context: context,
            value: question.text,
            hint: 'ما هو السؤال؟',
            isDark: isDark,
            onChanged: (val) =>
                onUpdate(_copyWithQuestion(question, text: val)),
          ),

          // Passage selector dropdown
          if (passages.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacing16),
            _buildPassageSelector(context, isDark),
          ],

          const SizedBox(height: AppTokens.spacing16),

          // Options section - stacked vertically on phone
          Text(
            'حدد أ ب ج أو د',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedColor(context),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (optIndex) => _buildOptionRow(optIndex, isDark)),
        ],
      ),
    );
  }

  Widget _buildUnderlineInput({
    required BuildContext context,
    required String value,
    required String hint,
    required bool isDark,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: value,
          maxLines: 2,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: false,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPassageSelector(BuildContext context, bool isDark) {
    final currentPassageId = getPassageValue(question.passage);
    final hasExistingPassage = question.passage?.isNotEmpty == true;
    final selectedPassageId =
        hasExistingPassage && !passages.any((p) => p['id'] == currentPassageId)
        ? '__existing__'
        : (currentPassageId ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPassageId.isEmpty ? null : selectedPassageId,
          isExpanded: true,
          hint: Text(
            'اختر فقرة (اختياري)',
            style: TextStyle(color: Colors.grey[400]),
          ),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('بد فقرة')),
            ...passages.map(
              (p) => DropdownMenuItem<String>(
                value: p['id'],
                child: Text(p['title'] ?? '', overflow: TextOverflow.ellipsis),
              ),
            ),
            if (hasExistingPassage && currentPassageId?.isNotEmpty == true)
              const DropdownMenuItem<String>(
                value: '__existing__',
                child: Text(
                  'قرائة محفوظة',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null || value.isEmpty) {
              onUpdate(_copyWithQuestion(question, passage: ''));
            } else if (value == '__existing__') {
              return;
            } else {
              final passageContent = getPassageContent(value);
              onUpdate(
                _copyWithQuestion(question, passage: passageContent ?? ''),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildOptionRow(int optIndex, bool isDark) {
    final option = optIndex < question.options.length
        ? question.options[optIndex]
        : Option(id: 'o${optIndex + 1}', text: '', isCorrect: false);
    final isCorrect = option.isCorrect;
    final correctIdx = question.options.indexWhere((o) => o.isCorrect);
    final isSelectedCorrect = correctIdx >= 0 && correctIdx == optIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Radio button
          GestureDetector(
            onTap: () {
              final updatedOpts = <Option>[];
              for (int i = 0; i < question.options.length; i++) {
                updatedOpts.add(
                  Option(
                    id: question.options[i].id,
                    text: question.options[i].text,
                    isCorrect: i == optIndex,
                  ),
                );
              }
              onUpdate(_copyWithQuestion(question, options: updatedOpts));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelectedCorrect ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelectedCorrect ? Colors.green : Colors.transparent,
              ),
              child: isSelectedCorrect
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Option letter (A, B, C, D)
          Text(
            ['أ', 'ب', 'ج', 'د'][optIndex],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelectedCorrect ? Colors.green : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          // Underline input
          Expanded(
            child: TextFormField(
              initialValue: option.text,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'إجابة...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: false,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isSelectedCorrect ? Colors.green : AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
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

  Question _copyWithQuestion(
    Question q, {
    String? id,
    String? text,
    String? passage,
    List<Option>? options,
  }) {
    return Question(
      id: id ?? q.text,
      text: text ?? q.text,
      passage: passage ?? q.passage,
      options: options ?? q.options,
    );
  }
}
