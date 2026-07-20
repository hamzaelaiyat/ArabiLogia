import 'package:flutter/material.dart';

class EditProfileDialog {
  static Future<void> show({
    required BuildContext context,
    required String? initialFullName,
    required String? initialUsername,
    required Future<bool> Function(String fullName, String username) onSave,
  }) async {
    final nameController = TextEditingController(text: initialFullName);
    final usernameController = TextEditingController(text: initialUsername);

    try {
      await showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('تعديل الملف الشخصي'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final success = await onSave(
                      nameController.text.trim(),
                      usernameController.text.trim(),
                    );
                    if (success) {
                      scaffold.showSnackBar(
                        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
                      );
                      nav.pop();
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      nameController.dispose();
      usernameController.dispose();
    }
  }
}
