import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/admin/widgets/passage_header.dart';
import 'package:arabilogia/features/admin/widgets/passage_empty_state.dart';
import 'package:arabilogia/features/admin/widgets/passage_list_item.dart';
import 'package:arabilogia/features/admin/widgets/passage_add_form.dart';

class PassageManager extends StatelessWidget {
  final List<Map<String, String>> passages;
  final Function(String, String, String) onAddPassage;
  final Function(int) onDeletePassage;

  const PassageManager({
    super.key,
    required this.passages,
    required this.onAddPassage,
    required this.onDeletePassage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PassageHeader(onAddTap: () => _showAddDialog(context, isDark)),
        const SizedBox(height: AppTokens.spacing16),
        if (passages.isEmpty)
          const PassageEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: passages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) => PassageListItem(
              passage: passages[idx],
              index: idx,
              onDelete: () => onDeletePassage(idx),
            ),
          ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PassageAddForm(
        isDark: isDark,
        onAdd: (title, content, imagePath) {
          onAddPassage(title, content, imagePath);
        },
      ),
    );
  }
}
