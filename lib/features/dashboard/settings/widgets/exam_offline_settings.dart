import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/widgets/potato_switch.dart';

class ExamOfflineSettings extends StatelessWidget {
  const ExamOfflineSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: TestKeys.settingsExamOffline,
      child: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final prefs = snapshot.data!;
          final autoDownload = prefs.getBool('auto_download_exams') ?? true;

          return StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  PotatoSwitchListTile(
                    secondary: const Icon(Icons.download_for_offline_outlined),
                    title: const Text('تنزيل المحاضرات تلقائياً'),
                    subtitle: const Text('للحصول على تجربة سلسة بدون إنترنت'),
                    value: autoDownload,
                    onChanged: (value) async {
                      await prefs.setBool('auto_download_exams', value);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.orange,
                    ),
                    title: const Text('مسح المحاضرات المحملة'),
                    onTap: () async {
                      final keys = prefs.getKeys().where(
                        (k) => k.startsWith('offline_exam_'),
                      );
                      for (final key in keys) {
                        await prefs.remove(key);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم مسح التخزين المؤقت للامتحانات'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
