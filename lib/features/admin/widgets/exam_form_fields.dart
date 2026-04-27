import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class ExamFormFields extends StatelessWidget {
  final String title;
  final String selectedCategoryId;
  final int selectedGrade;
  final int durationMinutes;
  final bool durationEnabled;
  final Function(String) onTitleChanged;
  final Function(String) onCategoryChanged;
  final Function(int) onGradeChanged;
  final Function(int) onDurationChanged;
  final Function(bool) onDurationToggle;

  const ExamFormFields({
    super.key,
    required this.title,
    required this.selectedCategoryId,
    required this.selectedGrade,
    required this.durationMinutes,
    required this.durationEnabled,
    required this.onTitleChanged,
    required this.onCategoryChanged,
    required this.onGradeChanged,
    required this.onDurationChanged,
    required this.onDurationToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('عنوان الامتحان'),
        TextFormField(
          initialValue: title,
          decoration: _decoration(
            'أدخل عنوان الامتحان...',
            Icons.title,
            isDark,
          ),
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: AppTokens.spacing24),
        _label('الفرع'),
        _buildCategoryDropdown(context, isDark),
        const SizedBox(height: AppTokens.spacing24),
        _label('الصف الدراسي'),
        _buildGradeDropdown(context, isDark),
        const SizedBox(height: AppTokens.spacing24),
        _durationToggle(context),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: AppTokens.fontSizeMd,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  InputDecoration _decoration(
    String hint,
    IconData icon,
    bool isDark,
  ) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
    border: OutlineInputBorder(
      borderRadius: AppTokens.radiusMdAll,
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _buildCategoryDropdown(BuildContext context, bool isDark) {
    final cats = [
      'arabic',
      'english',
      'french',
      'math',
      'science',
      'history',
      'geography',
      'art',
      'music',
      'religion',
      'computer',
    ];
    final names = {
      'arabic': 'اللغة العربية',
      'english': 'الإنجليزية',
      'french': 'الفرنسية',
      'math': 'الرياضيات',
      'science': 'العلوم',
      'history': 'التاريخ',
      'geography': 'الجغرافيا',
      'art': 'الفنون',
      'music': 'الموسيقى',
      'religion': 'التربية الدينية',
      'computer': 'الحاسب الآلي',
    };
    return DropdownButtonFormField<String>(
      initialValue: selectedCategoryId,
      decoration: _decoration('اختر الفرع', Icons.category_outlined, isDark),
      dropdownColor: isDark ? AppColors.bgDark : Colors.white,
      items: cats
          .map((c) => DropdownMenuItem(value: c, child: Text(names[c] ?? c)))
          .toList(),
      onChanged: (v) {
        if (v != null) onCategoryChanged(v);
      },
    );
  }

  Widget _buildGradeDropdown(BuildContext context, bool isDark) {
    return DropdownButtonFormField<int>(
      initialValue: selectedGrade,
      decoration: _decoration('اختر الصف', Icons.school_outlined, isDark),
      dropdownColor: isDark ? AppColors.bgDark : Colors.white,
      items: const [
        DropdownMenuItem(value: 1, child: Text('الأول الثانوي')),
        DropdownMenuItem(value: 2, child: Text('الثاني الثانوي')),
        DropdownMenuItem(value: 3, child: Text('الثالث الثانوي')),
      ],
      onChanged: (v) {
        if (v != null) onGradeChanged(v);
      },
    );
  }

  Widget _durationToggle(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('تفعيل المؤقت'),
            Switch.adaptive(
              value: durationEnabled,
              activeTrackColor: AppColors.primary,
              onChanged: onDurationToggle,
            ),
          ],
        ),
        if (durationEnabled) ...[
          const SizedBox(height: AppTokens.spacing12),
          TextFormField(
            initialValue: durationMinutes.toString(),
            keyboardType: TextInputType.number,
            decoration: _decoration(
              'المدة بالدقائق',
              Icons.timer_outlined,
              Theme.of(context).brightness == Brightness.dark,
            ),
            onChanged: (v) {
              final p = int.tryParse(v);
              if (p != null) onDurationChanged(p);
            },
          ),
        ],
      ],
    );
  }
}
