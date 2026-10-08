import 'package:flutter/material.dart';
import 'package:arabilogia/core/widgets/responsive_overlay.dart';

class AddContentSheet extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddYoutube;
  final VoidCallback onAddQuiz;

  const AddContentSheet({
    super.key,
    required this.onAddText,
    required this.onAddYoutube,
    required this.onAddQuiz,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onAddText,
    required VoidCallback onAddYoutube,
    required VoidCallback onAddQuiz,
  }) {
    return ResponsiveOverlay.show(
      context: context,
      title: 'إضافة عنصر إلى المحاضرة',
      child: AddContentSheet(
        onAddText: onAddText,
        onAddYoutube: onAddYoutube,
        onAddQuiz: onAddQuiz,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'إضافة عنصر إلى المحاضرة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                child: Icon(Icons.text_fields),
              ),
              title: const Text('إضافة نص'),
              subtitle: const Text('محتوى مقروء غني بالتنسيق'),
              onTap: () {
                Navigator.pop(context);
                onAddText();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                child: Icon(Icons.video_library),
              ),
              title: const Text('إضافة يوتيوب'),
              subtitle: const Text('رابط فيديو شرح المحاضرة'),
              onTap: () {
                Navigator.pop(context);
                onAddYoutube();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                child: Icon(Icons.assignment),
              ),
              title: const Text('إضافة اختبار قصير (امتحن)'),
              subtitle: const Text(
                'اختبار بدون نقاط وبدون مؤقت كجزء من المحاضرة',
              ),
              onTap: () {
                Navigator.pop(context);
                onAddQuiz();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
