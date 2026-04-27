import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/services/potato_mode_service.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TeacherSettingsScreen extends StatelessWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GlassAppBar(
          title: const Text('إعدادات المعلم'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Consumer<PotatoModeProvider>(
          builder: (context, potato, child) {
            return ListView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              children: [
                _buildSectionTitle(context, 'وضع الأداء'),
                _buildPerformanceModeSelector(context, potato),
                const SizedBox(height: AppTokens.spacing16),
                _buildSectionTitle(context, 'الحساب'),
                _buildLogoutButton(context),
                const SizedBox(height: 80),
              ],
            );
          },
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

  Widget _buildPerformanceModeSelector(
    BuildContext context,
    PotatoModeProvider potato,
  ) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.speed, color: _getPotatoColor(potato.level)),
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
                  selectedColor: _getPotatoColor(level).withValues(alpha: 0.3),
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
                potato.setPotatoLevel(PotatoLevel.off);
              } else {
                potato.setPotatoLevel(PotatoLevel.tiny);
              }
            },
          ),
        ],
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

  Widget _buildLogoutButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
        trailing: const Icon(Icons.chevron_left, color: Colors.red),
        onTap: () => _showSignOutDialog(context),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
