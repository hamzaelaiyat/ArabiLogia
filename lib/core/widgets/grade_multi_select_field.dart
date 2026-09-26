import 'package:flutter/material.dart';

import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

/// Multi-grade picker for lectures and exams.
///
/// A single selection behaves exactly like the old single-grade dropdown.
/// Choosing several grades makes one shared piece of content visible to every
/// selected grade, so the same lesson never has to be recreated once per
/// track.
class GradeMultiSelectField extends StatelessWidget {
  const GradeMultiSelectField({
    super.key,
    required this.selectedGradeIds,
    required this.onChanged,
    this.label = 'الصفوف المستهدفة',
  });

  final List<int> selectedGradeIds;
  final ValueChanged<List<int>> onChanged;
  final String label;

  bool get _isAllSelected => selectedGradeIds.contains(GradeMetadata.allGrades);

  void _toggle(int id) {
    if (id == GradeMetadata.allGrades) {
      onChanged(const [GradeMetadata.allGrades]);
      return;
    }

    final next = Set<int>.from(selectedGradeIds)
      ..remove(GradeMetadata.allGrades);

    if (next.contains(id)) {
      // Never allow an empty selection: an empty grade_ids would silently fall
      // back to the legacy scalar column and behave surprisingly.
      if (next.length == 1) return;
      next.remove(id);
    } else {
      next.add(id);
    }

    onChanged(GradeMetadata.normalizeGradeIds(next));
  }

  String get _summary {
    if (_isAllSelected) return 'جميع الصفوف';
    if (selectedGradeIds.length == 1) {
      return GradeMetadata.getById(selectedGradeIds.first)?.name ?? '';
    }
    return 'مشارك مع ${selectedGradeIds.length} صفوف';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTokens.spacing6),
        Wrap(
          spacing: AppTokens.spacing6,
          runSpacing: AppTokens.spacing6,
          children: [
            ChoiceChip(
              label: const Text('الكل'),
              selected: _isAllSelected,
              onSelected: (_) => _toggle(GradeMetadata.allGrades),
            ),
            for (final grade in GradeMetadata.grades)
              ChoiceChip(
                label: Text(grade.name),
                selected: selectedGradeIds.contains(grade.id),
                // Stays tappable while "all grades" is active: picking a grade
                // then narrows the selection to just that grade, which is
                // faster than clearing "all grades" first.
                onSelected: (_) => _toggle(grade.id),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing4),
        Text(
          _summary,
          key: const Key('gradeMultiSelectSummary'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
