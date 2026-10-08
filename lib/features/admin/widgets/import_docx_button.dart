import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/responsive_overlay.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_state.dart';
import 'package:arabilogia/features/admin/services/docx_exam_parser.dart';
import 'package:arabilogia/features/admin/widgets/import_docx_preview_dialog.dart';

class ImportDocxButton extends StatelessWidget {
  final bool isMobile;

  const ImportDocxButton({super.key, this.isMobile = false});

  Future<void> pickAndParse(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      if (!context.mounted) return;

      final file = result.files.first;
      var bytes = file.bytes;
      if (bytes == null && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
        } catch (_) {
          bytes = null;
        }
      }
      if (bytes == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن قراءة الملف'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      DocxParseResult parseResult;
      try {
        parseResult = DocxExamParser.parse(bytes);
      } catch (e) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحليل الملف: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (parseResult.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على أسئلة في الملف'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      final confirmed = await ResponsiveOverlay.show<bool>(
        context: context,
        title: 'معاينة الاستيراد',
        child: ImportDocxPreviewDialog(result: parseResult),
      );

      if (confirmed == true && context.mounted) {
        context.read<ExamEditorState>().importFromDocx(parseResult);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم استيراد ${parseResult.questions.length} سؤال و ${parseResult.passages.length} فقرة',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ غير متوقع: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.fgDark : AppColors.fgLight;

    return Tooltip(
      message: 'استيراد من ملف .docx',
      child: GestureDetector(
        onTap: () => pickAndParse(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: AppTokens.radiusMdAll,
          ),
          child: Icon(
            Icons.file_upload_outlined,
            color: iconColor.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
      ),
    );
  }
}
