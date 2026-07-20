import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/widgets/potato_switch.dart';

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: TestKeys.settingsNotifications,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final notifications = Map<String, dynamic>.from(
            authProvider.state.user?.userMetadata?['notifications'] ?? {},
          );

          final examNotify = notifications['exam_results'] ?? true;
          final remindersNotify = notifications['reminders'] ?? false;

          return Column(
            children: [
              PotatoSwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('إشعارات المحاضرات الجديدة'),
                value: examNotify,
                onChanged: (value) async {
                  notifications['exam_results'] = value;
                  await authProvider.updateProfile(
                    notifications: Map<String, bool>.from(notifications),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'تم تفعيل إشعارات المحاضرات'
                              : 'تم إيقاف إشعارات المحاضرات',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              PotatoSwitchListTile(
                secondary: const Icon(Icons.timer_outlined),
                title: const Text('تذكير بالمحاضرات'),
                value: remindersNotify,
                onChanged: (value) async {
                  notifications['reminders'] = value;
                  await authProvider.updateProfile(
                    notifications: Map<String, bool>.from(notifications),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'تم تفعيل تذكير المحاضرات'
                              : 'تم إيقاف تذكير المحاضرات',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
