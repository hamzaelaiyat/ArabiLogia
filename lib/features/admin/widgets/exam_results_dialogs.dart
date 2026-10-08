import 'package:flutter/material.dart';
import 'package:arabilogia/core/widgets/responsive_confirm.dart';
import 'package:arabilogia/core/widgets/responsive_overlay.dart';

Future<bool> showLectureDeleteConfirmDialog(
  BuildContext context,
  String title,
) async {
  return showResponsiveConfirmToast(
    context: context,
    message:
        'هل أنت متأكد من حذف محاضرة "$title"؟ لا يمكن التراجع عن هذا الإجراء.',
    confirmLabel: 'حذف',
    confirmColor: Colors.red,
  );
}

Future<bool> showUnpublishConfirmDialog(
  BuildContext context,
  String title,
) async {
  return showResponsiveConfirmToast(
    context: context,
    message:
        'هل أنت متأكد من تحويل محاضرة "$title" إلى مسودة؟ لن يتمكن الطلاب من رؤيتها.',
    confirmLabel: 'تحويل لمسودة',
    confirmColor: Colors.orange,
  );
}

Future<bool> showPublishConfirmDialog(
  BuildContext context,
  String title,
) async {
  return showResponsiveConfirmToast(
    context: context,
    message:
        'هل أنت متأكد من نشر محاضرة "$title"؟ سيتمكن الطلاب من رؤيتها ودراستها.',
    confirmLabel: 'نشر',
    confirmColor: Colors.green,
  );
}

void showWrongAnswersSheet(BuildContext context, dynamic wrongAnswers) {
  List<String> questions = [];
  if (wrongAnswers is List) {
    questions = wrongAnswers.map((q) => q.toString()).toList();
  }

  ResponsiveOverlay.show(
    context: context,
    title: 'الأسئلة التي أخطأ فيها الطالب',
    mobileBuilder: (_) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(child: _WrongAnswersContent(questions: questions)),
    ),
    child: _WrongAnswersContent(questions: questions),
  );
}

class _WrongAnswersContent extends StatelessWidget {
  final List<String> questions;

  const _WrongAnswersContent({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأسئلة التي أخطأ فيها الطالب:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (questions.isEmpty)
            const Text('أجاب الطالب على جميع الأسئلة بشكل صحيح! 🎉')
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: questions.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text('سؤال ID: ${questions[index]}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
