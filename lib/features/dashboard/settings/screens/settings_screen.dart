import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/providers/theme_provider.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/legal/widgets/legal_bottom_sheet.dart';
import 'package:arabilogia/core/widgets/glass_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.all(AppTokens.spacing8),
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
            const SizedBox(height: AppTokens.spacing24),
            _buildLogoutButton(context),
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
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.animation_outlined),
                title: const Text('تفعيل الحركة'),
                value: potato.animationsEnabled,
                onChanged: (value) {
                  if (value) {
                    potato.setPotatoLevel(PotatoLevel.big);
                  } else {
                    potato.setPotatoLevel(PotatoLevel.tiny);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getPotatoColor(PotatoLevel level) {
    switch (level) {
      case PotatoLevel.big:
        return Colors.green;
      case PotatoLevel.medium:
        return Colors.orange;
      case PotatoLevel.small:
        return Colors.deepOrange;
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
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final metadata = authProvider.state.user?.userMetadata ?? {};
              final isPublic = metadata['is_public'] ?? true;
              final hideAvatar = metadata['hide_avatar'] ?? false;

              return Column(
                children: [
                  _buildSectionHeader(context, 'الخصوصية'),
                  const SizedBox(height: AppTokens.spacing8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.visibility_outlined),
                          title: const Text('إظهار ملفي للآخرين'),
                          value: isPublic,
                          onChanged: (value) async {
                            await authProvider.updateProfile(isPublic: value);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.no_photography_outlined),
                          title: const Text('إخفاء صورتي في لوحة الصدارة'),
                          value: hideAvatar,
                          onChanged: (value) async {
                            await authProvider.updateProfile(hideAvatar: value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
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
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('إشعارات الامتحانات الجديدة'),
                value: examNotify,
                onChanged: (value) async {
                  notifications['exam_results'] = value;
                  await authProvider.updateProfile(
                    notifications: Map<String, bool>.from(notifications),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.timer_outlined),
                title: const Text('تذكير بالامتحانات'),
                value: remindersNotify,
                onChanged: (value) async {
                  notifications['reminders'] = value;
                  await authProvider.updateProfile(
                    notifications: Map<String, bool>.from(notifications),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
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
                  SwitchListTile(
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing4,
        vertical: AppTokens.spacing8,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
