import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor.dart';

class ExamEditorScreen extends StatelessWidget {
  final Exam? existingExam;

  const ExamEditorScreen({super.key, this.existingExam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ExamEditor(
                existingExam: existingExam,
                onSave: (exam) => _handleSave(context, exam),
                onCancel: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, Exam exam) async {
    try {
      final repo = ExamRepository();
      await repo.upsertExam(exam);

      if (!context.mounted) return;

      if (exam.isPublished) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر الامتحان بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الامتحان بنجاح'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
      context.pop(exam);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحفظ: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
