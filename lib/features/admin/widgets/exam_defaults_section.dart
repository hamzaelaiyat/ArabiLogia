import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/admin/providers/teacher_exam_defaults_provider.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';

class ExamDefaultsSection extends StatelessWidget {
  const ExamDefaultsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherExamDefaultsProvider>(
      builder: (context, defaults, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  context: context,
                  label: 'العنوان الافتراضي',
                  value: defaults.defaults.defaultTitle,
                  onChanged: (v) => defaults.setDefaultTitle(v),
                ),
                const SizedBox(height: AppTokens.spacing12),
                _buildGradeDropdown(context, defaults),
                const SizedBox(height: AppTokens.spacing12),
                _buildDurationField(context, defaults),
                const SizedBox(height: AppTokens.spacing12),
                _buildToggle(
                  context: context,
                  label: 'تفعيل المؤقت',
                  value: defaults.defaults.defaultDurationEnabled,
                  onChanged: (v) => defaults.setDefaultDurationEnabled(v),
                ),
                const SizedBox(height: AppTokens.spacing12),
                _buildPointsField(context, defaults),
                const SizedBox(height: AppTokens.spacing12),
                _buildToggle(
                  context: context,
                  label: 'خلط الأسئلة',
                  value: defaults.defaults.defaultShuffleQuestions,
                  onChanged: (v) => defaults.setDefaultShuffleQuestions(v),
                ),
                const SizedBox(height: AppTokens.spacing12),
                _buildToggle(
                  context: context,
                  label: 'إظهار الإجابات الصحيحة',
                  value: defaults.defaults.defaultShowCorrectAnswers,
                  onChanged: (v) => defaults.setDefaultShowCorrectAnswers(v),
                ),
                const SizedBox(height: AppTokens.spacing12),
                _buildToggle(
                  context: context,
                  label: 'إظهار النتيجة',
                  value: defaults.defaults.defaultShowScore,
                  onChanged: (v) => defaults.setDefaultShowScore(v),
                ),
                const SizedBox(height: AppTokens.spacing16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => defaults.resetToDefaults(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('إعادة تعيين الافتراضيات'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }

  static Widget _buildGradeDropdown(BuildContext context, TeacherExamDefaultsProvider defaults) {
    final grades = GradeMetadata.grades;
    return DropdownButtonFormField<int>(
      initialValue: defaults.defaults.defaultGrade,
      decoration: const InputDecoration(
        labelText: 'الصف الافتراضي',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: grades.map((g) {
        return DropdownMenuItem(
          value: g.id,
          child: Text(g.name),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) defaults.setDefaultGrade(v);
      },
    );
  }

  static Widget _buildDurationField(BuildContext context, TeacherExamDefaultsProvider defaults) {
    return TextFormField(
      initialValue: defaults.defaults.defaultDurationMinutes.toString(),
      decoration: const InputDecoration(
        labelText: 'المدة الافتراضية (دقائق)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final mins = int.tryParse(v);
        if (mins != null && mins > 0) {
          defaults.setDefaultDurationMinutes(mins);
        }
      },
    );
  }

  static Widget _buildPointsField(BuildContext context, TeacherExamDefaultsProvider defaults) {
    return TextFormField(
      initialValue: defaults.defaults.defaultPoints.toString(),
      decoration: const InputDecoration(
        labelText: 'النقاط الافتراضية لكل سؤال',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final pts = int.tryParse(v);
        if (pts != null && pts > 0) {
          defaults.setDefaultPoints(pts);
        }
      },
    );
  }

  static Widget _buildToggle({
    required BuildContext context,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.foreground(context))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}
