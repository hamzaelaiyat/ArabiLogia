import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';

class OptionsGrid extends StatelessWidget {
  final List<Option> options;
  final Function(List<Option>) onOptionsChanged;

  const OptionsGrid({
    super.key,
    required this.options,
    required this.onOptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
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
      itemBuilder: (ctx, idx) => _buildOption(idx),
    );
  }

  Widget _buildOption(int idx) {
    final opt = idx < options.length
        ? options[idx]
        : Option(id: 'o${idx + 1}', text: '', isCorrect: false);
    final isCorrect = opt.isCorrect;
    final correctIdx = options.indexWhere((o) => o.isCorrect);
    return AnimatedContainer(
      duration: AppTokens.durationFast,
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.02),
        borderRadius: AppTokens.radiusMdAll,
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.grey.withValues(alpha: 0.2),
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Radio<int>(
            value: idx,
            groupValue: correctIdx >= 0 ? correctIdx : null,
            activeColor: Colors.green,
            onChanged: (v) {
              if (v != null) {
                final updated = <Option>[];
                for (int i = 0; i < options.length; i++)
                  updated.add(
                    Option(
                      id: options[i].id,
                      text: options[i].text,
                      isCorrect: i == v,
                    ),
                  );
                onOptionsChanged(updated);
              }
            },
          ),
          Expanded(
            child: TextFormField(
              initialValue: opt.text,
              style: const TextStyle(fontSize: AppTokens.fontSizeMd),
              decoration: const InputDecoration(
                hintText: 'الخيار...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (v) {
                final updated = <Option>[];
                for (int i = 0; i < options.length; i++)
                  updated.add(
                    Option(
                      id: options[i].id,
                      text: i == idx ? v : options[i].text,
                      isCorrect: options[i].isCorrect,
                    ),
                  );
                onOptionsChanged(updated);
              },
            ),
          ),
        ],
      ),
    );
  }
}
