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
  final List<Map<String, String>> passages;
  final bool isMobile;
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

  const ExamSettingsPanel({
    super.key,
    required this.title,
    required this.selectedCategoryId,
    required this.selectedGrade,
    required this.durationMinutes,
    required this.durationEnabled,
    required this.isPublished,
    required this.passages,
    this.isMobile = false,
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
              _buildHeader(context, isDark),
              const SizedBox(height: AppTokens.spacing24),
              _buildSectionTitle('الإعدادات', Icons.settings_outlined, isDark),
              const SizedBox(height: AppTokens.spacing32),
              _buildTitleField(context, isDark),
              const SizedBox(height: AppTokens.spacing24),
              _buildCategoryField(context, isDark),
              const SizedBox(height: AppTokens.spacing24),
              _buildGradeField(context, isDark),
              const SizedBox(height: AppTokens.spacing24),
              _buildDurationField(context),
              const SizedBox(height: AppTokens.spacing32),
              _buildPassagesSection(context, isDark),
              const SizedBox(height: AppTokens.spacing32),
              _buildActionButtons(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTokens.fontSize2xl,
            fontWeight: FontWeight.bold,
            fontFamily: AppTokens.fontFamilyDisplay,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
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

  Widget _buildTitleField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('عنوان الامتحان'),
        TextFormField(
          initialValue: title,
          decoration: _inputDecoration(
            'أدخل عنوان الامتحان...',
            Icons.title,
            isDark,
          ),
          onChanged: onTitleChanged,
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('المادة'),
        DropdownButtonFormField<String>(
          value: selectedCategoryId,
          decoration: _inputDecoration(
            'اختر المادة',
            Icons.category_outlined,
            isDark,
          ),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          items: CategoryMetadata.categories
              .map(
                (cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 12),
                      Text(cat.name),
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

  Widget _buildGradeField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('الصف الدراسي'),
        DropdownButtonFormField<int>(
          value: selectedGrade,
          decoration: _inputDecoration(
            'اختر الصف',
            Icons.school_outlined,
            isDark,
          ),
          dropdownColor: isDark ? AppColors.bgDark : Colors.white,
          items: const [
            DropdownMenuItem(value: 1, child: Text('الأول الثانوي')),
            DropdownMenuItem(value: 2, child: Text('الثاني الثانوي')),
            DropdownMenuItem(value: 3, child: Text('الثالث الثانوي')),
          ],
          onChanged: (val) {
            if (val != null) onGradeChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildDurationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('تفعيل المؤقت'),
            Switch.adaptive(
              value: durationEnabled,
              activeColor: AppColors.primary,
              onChanged: onDurationToggle,
            ),
          ],
        ),
        if (durationEnabled) ...[
          const SizedBox(height: AppTokens.spacing12),
          TextFormField(
            initialValue: durationMinutes.toString(),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              'المدة بالدقائق',
              Icons.timer_outlined,
              Theme.of(context).brightness == Brightness.dark,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) onDurationChanged(parsed);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPassagesSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.article_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'المقروءات',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddPassageDialog(context),
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              tooltip: 'إضافة مقروء',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing16),
        if (passages.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Text(
              'لم تقم بإضافة مقروءات بعد.\nاضغط + لإضافة مقروء جديد.',
              style: TextStyle(
                color: AppColors.mutedColor(context),
                fontSize: AppTokens.fontSizeSm,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...List.generate(
            passages.length,
            (idx) => _buildPassageItem(context, passages[idx], idx, isDark),
          ),
      ],
    );
  }

  Widget _buildPassageItem(
    BuildContext context,
    Map<String, String> passage,
    int idx,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passage['title'] ?? 'بدون عنوان',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppTokens.fontSizeSm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${passage['content']?.length ?? 0} حرف',
                  style: TextStyle(
                    color: AppColors.mutedColor(context),
                    fontSize: AppTokens.fontSizeXs,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onDeletePassage(idx),
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showAddPassageDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مقروء جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المقروء',
                  hintText: 'مثال: مقروء الوحدة الأولى',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'نص المقروء',
                  hintText: 'أدخل النص الكامل للمقروء...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                onAddPassage(titleController.text, contentController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSaveDraft,
            icon: const Icon(Icons.save_outlined),
            label: Text(isPublished ? 'حفظ التعديلات' : 'حفظ كمسودة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black87,
              side: BorderSide(color: isDark ? Colors.white38 : Colors.black38),
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
              backgroundColor: isPublished ? Colors.green : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppTokens.radiusLgAll,
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
