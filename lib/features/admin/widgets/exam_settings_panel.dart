import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';

class ExamSettingsPanel extends StatelessWidget {
  final String title;
  final String selectedCategoryId;
  final int selectedGrade;
  final int durationMinutes;
  final bool durationEnabled;
  final bool isPublished;
  final bool isMobile;
  final Function(String) onTitleChanged;
  final Function(String) onCategoryChanged;
  final Function(int) onGradeChanged;
  final Function(int) onDurationChanged;
  final Function(bool) onDurationToggle;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  const ExamSettingsPanel({
    super.key,
    required this.title,
    required this.selectedCategoryId,
    required this.selectedGrade,
    required this.durationMinutes,
    required this.durationEnabled,
    required this.isPublished,
    this.isMobile = false,
    required this.onTitleChanged,
    required this.onCategoryChanged,
    required this.onGradeChanged,
    required this.onDurationChanged,
    required this.onDurationToggle,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.bgDark : AppColors.bgLight,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? AppTokens.spacing16 : AppTokens.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTokens.spacing24),
              _buildTitleField(context),
              const SizedBox(height: AppTokens.spacing16),
              _buildCategoryField(context),
              const SizedBox(height: AppTokens.spacing16),
              _buildGradeField(context),
              const SizedBox(height: AppTokens.spacing16),
              _buildDurationField(context),
              const SizedBox(height: AppTokens.spacing24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'رجوع',
        ),
        const Spacer(),
        Text(
          'إنشاء امتحان',
          style: TextStyle(
            fontSize: AppTokens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedColor(context),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTokens.fontSizeMd,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('عنوان الامتحان'),
        TextFormField(
          initialValue: title,
          decoration: _inputDecoration('أدخل عنوان الامتحان...', Icons.title, context),
          onChanged: onTitleChanged,
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('الفرع'),
        DropdownButtonFormField<String>(
          value: selectedCategoryId,
          decoration: _inputDecoration('اختر الفرع', Icons.category_outlined, context),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          isExpanded: true,
          items: CategoryMetadata.categories
              .map(
                (cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          cat.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) onCategoryChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildGradeField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('الصف الدراسي'),
        DropdownButtonFormField<int>(
          value: selectedGrade,
          decoration: _inputDecoration('اختر الصف', Icons.school_outlined, context),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 1, child: Text('الأول الثانوية')),
            DropdownMenuItem(value: 2, child: Text('الثاني الثانوية')),
            DropdownMenuItem(value: 3, child: Text('الثالث الثانوية')),
          ],
          onChanged: (val) {
            if (val != null) onGradeChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildDurationField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('تفعيل المؤقت'),
            _TimerToggle(
              value: durationEnabled,
              onChanged: onDurationToggle,
              isDark: isDark,
            ),
          ],
        ),
        if (durationEnabled) ...[
          const SizedBox(height: AppTokens.spacing12),
          TextFormField(
            initialValue: durationMinutes.toString(),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('المدة بالدقائق', Icons.timer_outlined, context),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) onDurationChanged(parsed);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = AppColors.foreground(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSaveDraft,
            icon: const Icon(Icons.save_outlined),
            label: Text(isPublished ? 'حفظ التعديلات' : 'حفظ كمسودة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: fgColor,
              side: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppTokens.radiusLgAll,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onPublish,
            icon: Icon(isPublished ? Icons.check_circle : Icons.publish),
            label: Text(isPublished ? 'تم النشر' : 'نشر الآن'),
            style: FilledButton.styleFrom(
              backgroundColor: isPublished ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppTokens.radiusLgAll,
              ),
              elevation: AppTokens.elevationNone,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    BuildContext context,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.surface(context),
      border: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _TimerToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _TimerToggle({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: value 
              ? AppColors.primary 
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: AppTokens.durationFast,
              left: value ? 28 : 4,
              top: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  value ? Icons.timer : Icons.timer_off_outlined,
                  size: 14,
                  color: value ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
