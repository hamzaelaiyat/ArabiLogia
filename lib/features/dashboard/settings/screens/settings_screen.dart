import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/core/widgets/glass_bottom_sheet.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';
import 'package:arabilogia/widgets/potato_switch.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/utils/anonymous_name_generator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GlassAppBar(title: const ResponsiveAppBarTitle('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.all(AppTokens.spacing8),
          // Extra bottom padding to ensure logout button is visible above bottom nav on mobile
          clipBehavior: Clip.none,
          children: [
            _buildSectionTitle(context, 'المظهر'),
            _buildThemeSelector(context),
            const SizedBox(height: AppTokens.spacing16),
            _buildSectionTitle(context, 'وضع الأداء'),
            _buildPerformanceModeSelector(context),
            const SizedBox(height: AppTokens.spacing16),
            _buildSectionTitle(context, 'الحساب'),
            _buildAccountSettings(context),
            const SizedBox(height: AppTokens.spacing16),
            _buildSectionTitle(context, 'الإشعارات'),
            _buildNotificationSettings(context),
            const SizedBox(height: AppTokens.spacing16),
            _buildSectionTitle(context, 'الامتحانات والتحميل'),
            _buildExamOfflineSettings(context),
            const SizedBox(height: AppTokens.spacing16),
            _buildSectionTitle(context, 'حول'),
            _buildAboutSection(context),
            // Extra bottom padding for mobile to ensure logout button is visible above nav bar
            const SizedBox(height: AppTokens.spacing24),
            _buildLogoutButton(context),
            const SizedBox(
              height: 80,
            ), // Extra space for bottom nav bar on mobile
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spacing4),
          child: SegmentedButton<ThemeModeOption>(
            segments: const [
              ButtonSegment<ThemeModeOption>(
                value: ThemeModeOption.light,
                label: Text('فاتح'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeModeOption>(
                value: ThemeModeOption.dark,
                label: Text('داكن'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment<ThemeModeOption>(
                value: ThemeModeOption.system,
                label: Text('تلقائي'),
                icon: Icon(Icons.settings_brightness_outlined),
              ),
            ],
            selected: {themeProvider.themeModeOption},
            onSelectionChanged: (Set<ThemeModeOption> selection) {
              themeProvider.setThemeMode(selection.first);
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceModeSelector(BuildContext context) {
    return Card(
      child: Consumer<PotatoModeProvider>(
        builder: (context, potato, child) {
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.speed,
                  color: _getPotatoColor(potato.level),
                ),
                title: const Text('وضع الأداء'),
                subtitle: Text(
                  potato.levelName,
                  style: TextStyle(
                    color: _getPotatoColor(potato.level),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppTokens.spacing8),
                child: Wrap(
                  spacing: AppTokens.spacing8,
                  runSpacing: AppTokens.spacing8,
                  children: PotatoLevel.values.map((level) {
                    final isSelected = potato.level == level;
                    final config = potato.getConfigForLevel(level);
                    return ChoiceChip(
                      label: Text(config.levelName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          potato.setPotatoLevel(level);
                        }
                      },
                      selectedColor: _getPotatoColor(
                        level,
                      ).withValues(alpha: 0.3),
                      avatar: isSelected
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: _getPotatoColor(level),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getPotatoColor(PotatoLevel level) {
    switch (level) {
      case PotatoLevel.off:
        return Colors.green;
      case PotatoLevel.sweet:
        return Colors.orange;
      case PotatoLevel.tiny:
        return Colors.red;
    }
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('تعديل الملف الشخصي'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          const Divider(height: 1),
          const _PrivacySection(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'حذف الحساب',
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_left, color: Colors.red),
            onTap: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
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
    // Show confirmation dialog first
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

    // Show loading
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
        Navigator.pop(context); // Dismiss loading

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
          // Guide user to subscribe
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
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => LegalBottomSheet.showAbout(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('الشروط والأحكام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => LegalBottomSheet.showTerms(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => LegalBottomSheet.showPrivacy(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        GlassBottomSheet.show(
          context: context,
          title: 'تسجيل الخروج',
          message: 'هل أنت متأكد من تسجيل الخروج؟',
          confirmLabel: 'تسجيل الخروج',
          cancelLabel: 'إلغاء',
          confirmColor: Colors.red,
          onConfirm: () async {
            await context.read<AuthProvider>().signOut();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
        );
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      icon: const Icon(Icons.logout),
      label: const Text('تسجيل الخروج'),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    GlassBottomSheet.show(
      context: context,
      title: 'حذف الحساب',
      message: 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف الحساب',
      cancelLabel: 'إلغاء',
      confirmColor: Colors.red,
      onConfirm: () async {
        // Mock deletion: Sign out and return to login
        await context.read<AuthProvider>().signOut();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
    );
  }

  Widget _buildExamOfflineSettings(BuildContext context) {
    return Card(
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
                    title: const Text('تنزيل الامتحانات تلقائياً'),
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
                    title: const Text('مسح الامتحانات المحملة'),
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

class _PrivacySection extends StatefulWidget {
  const _PrivacySection();

  @override
  State<_PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<_PrivacySection> {
  bool _hideAvatar = false;
  bool _hideName = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('hide_avatar, hide_name')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _hideAvatar = profile['hide_avatar'] ?? false;
          _hideName = profile['hide_name'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PrivacySection load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToDb({
    bool? hideAvatar,
    bool? hideName,
    String? randomName,
  }) async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      hideAvatar: hideAvatar,
      hideName: hideName,
      randomName: randomName,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hideName == true ? 'سيظهر اسم عشوائي في لوحة الصدارة' : 'تم الحفظ'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الحفظ، حاول مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Text(
        'الخصوصية',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
      ),
    );

    return Column(
      children: [
        header,
        const SizedBox(height: AppTokens.spacing8),
        Card(
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.no_photography_outlined,
                      title: 'إخفاء صورتي في لوحة الصدارة',
                      value: _hideAvatar,
                      onChanged: (value) async {
                        setState(() {
                          _hideAvatar = value;
                          if (!value) {
                            _hideName = false;
                          }
                        });
                        if (!value) {
                          await _saveToDb(hideName: false, randomName: null);
                        }
                        await _saveToDb(hideAvatar: value);
                      },
                    ),
                    if (_hideAvatar) ...[
                      const Divider(height: 1),
                      _buildToggleTile(
                        icon: Icons.person_off_outlined,
                        title: 'إخفاء حسابي في لوحة الصدارة',
                        subtitle: 'سيظهر اسم عشوائي بدلاً من اسمك الحقيقي',
                        value: _hideName,
                        onChanged: (value) async {
                          if (value) {
                            try {
                              final name = await AnonymousNameGenerator.generate(
                                supabase: Supabase.instance.client,
                              );
                              setState(() => _hideName = true);
                              await _saveToDb(hideName: true, randomName: name);
                            } catch (e) {
                              debugPrint('Name generation failed: $e');
                              setState(() => _hideName = false);
                            }
                          } else {
                            setState(() => _hideName = false);
                            await _saveToDb(hideName: false, randomName: null);
                          }
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeMd,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeSm,
                        color: AppColors.mutedColor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            _CustomSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _CustomSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: value ? 26 : 4,
              top: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
