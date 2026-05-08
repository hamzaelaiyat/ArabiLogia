import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.send_to_mobile,
                  color: AppColors.primary,
                ),
                title: const Text('فحص الإشعارات'),
                subtitle: const Text('إرسال إشعار تجريبي للأجهزة'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _sendTestNotification(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فحص الإشعارات'),
        content: const Text(
          'سيتم إرسال إشعار تجريبي إلى جهازك. تأكد من السماح بالإشعارات في المتصفح.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final supabase = Supabase.instance;
      final user = supabase.client.auth.currentUser;

      if (user == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى تسجيل الدخول أولاً'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final response = await supabase.client.functions.invoke(
        'send-test-notification',
        body: {'user_id': user.id},
      );

      if (context.mounted) {
        Navigator.pop(context);

        if (response.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ?? 'تم إرسال الإشعار التجريبي',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (response.data['message'] ==
            'User has no active push subscription') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى السماح بالإشعارات أولاً من المتصفح'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'فشل إرسال الإشعار'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
