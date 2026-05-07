import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_timer_toggle.dart';
import 'package:arabilogia/features/admin/widgets/exam_settings_action_buttons.dart';

class ExamSettingsPanel extends StatelessWidget {
  final String title;
  final String selectedCategoryId;
  final int selectedGrade;
  final int durationMinutes;
  final bool durationEnabled;
  final bool isPublished;
  final bool isMobile;
  final List<Map<String, String>> passages;
  final Function(String) onTitleChanged;
  final Function(String) onCategoryChanged;
  final Function(int) onGradeChanged;
  final Function(int) onDurationChanged;
  final Function(bool) onDurationToggle;
  final Function(String, String) onAddPassage;
  final Function(int) onDeletePassage;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onPreview;

  const ExamSettingsPanel({
    super.key,
    required this.title,
    required this.selectedCategoryId,
    required this.selectedGrade,
    required this.durationMinutes,
    required this.durationEnabled,
    required this.isPublished,
    this.isMobile = false,
    required this.passages,
    required this.onTitleChanged,
    required this.onCategoryChanged,
    required this.onGradeChanged,
    required this.onDurationChanged,
    required this.onDurationToggle,
    required this.onAddPassage,
    required this.onDeletePassage,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppTokens.spacing16 : AppTokens.spacing24,
            vertical: AppTokens.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isMobile) ...[
                Text(
                  isPublished ? 'تعديل الامتحان' : 'إعدادات الامتحان',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeXl,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTokens.fontFamilyDisplay,
                    color: AppColors.foreground(context),
                  ),
                ),
                const SizedBox(height: AppTokens.spacing24),
              ],
              _buildTitleField(context),
              const SizedBox(height: AppTokens.spacing16),
              _buildCategoryField(context),
              const SizedBox(height: AppTokens.spacing16),
              _buildGradeField(context),
              const SizedBox(height: AppTokens.spacing16),
              _buildDurationField(context),
              if (!isMobile) ...[
                const SizedBox(height: AppTokens.spacing32),
                const Divider(height: 1),
                const SizedBox(height: AppTokens.spacing24),
                _buildActionButtons(context),
              ],
              if (isMobile) const SizedBox(height: 100), // Space for bottom buttons
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, right: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTokens.fontSizeMd,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground(context).withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('عنوان الامتحان', context),
        TextFormField(
          initialValue: title,
          decoration: _inputDecoration('أدخل عنوان الامتحان...', Icons.title_rounded, context),
          onChanged: onTitleChanged,
          style: const TextStyle(fontSize: AppTokens.fontSizeMd),
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('الفرع', context),
        DropdownButtonFormField<String>(
          value: selectedCategoryId,
          decoration: _inputDecoration('اختر الفرع', Icons.category_rounded, context),
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
        _buildFieldLabel('الصف الدراسي', context),
        DropdownButtonFormField<int>(
          value: selectedGrade,
          decoration: _inputDecoration('اختر الصف', Icons.school_rounded, context),
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
            _buildFieldLabel('تفعيل المؤقت', context),
            ExamSettingsTimerToggle(
              value: durationEnabled,
              onChanged: onDurationToggle,
              isDark: isDark,
            ),
          ],
        ),
        if (durationEnabled) ...[
          const SizedBox(height: AppTokens.spacing8),
          TextFormField(
            initialValue: durationMinutes.toString(),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('المدة بالدقائق', Icons.timer_rounded, context),
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
    return ExamSettingsActionButtons(
      isPublished: isPublished,
      onSaveDraft: onSaveDraft,
      onPublish: onPublish,
      onPreview: onPreview,
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
      filled: true,
      fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
      border: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTokens.radiusMdAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}