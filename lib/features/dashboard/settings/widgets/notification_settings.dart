import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/widgets/potato_switch.dart';

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                title: const Text('إشعارات الامتحانات الجديدة'),
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
                              ? 'تم تفعيل إشعارات الامتحانات'
                              : 'تم إيقاف إشعارات الامتحانات',
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
                title: const Text('تذكير بالامتحانات'),
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
                              ? 'تم تفعيل تذكير الامتحانات'
                              : 'تم إيقاف تذكير الامتحانات',
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
