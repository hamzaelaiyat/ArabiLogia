import 'package:flutter/material.dart';

Future<bool> showUnpublishConfirmDialog(
  BuildContext context,
  String examTitle,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد إلغاء النشر'),
        content: Text(
          'هل أنت متأكد من رغبتك في إلغاء نشر امتحان "$examTitle"؟ لن يتمكن الطلاب من رؤيته، ولكن سيتم الاحتفاظ بالنتائج السابقة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إلغاء النشر'),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}

void showWrongAnswersSheet(
  BuildContext context,
  dynamic wrongAnswers,
) {
  List<String> questions = [];
  if (wrongAnswers is List) {
    questions = wrongAnswers.map((q) => q.toString()).toList();
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
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
              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                    title: Text('سؤال ID: ${questions[index]}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}