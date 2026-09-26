import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/switch_accounts_sheet.dart';
import 'package:arabilogia/features/dashboard/leaderboard/widgets/leaderboard_helpers.dart';
import 'package:arabilogia/core/widgets/confirmation_dialog.dart';

class UserAvatarAction extends StatelessWidget {
  const UserAvatarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.state.user;
    final userAvatar = user?.userMetadata?['avatar_url'] as String?;
    final fullName = user?.userMetadata?['full_name'] as String? ?? '';
    final avatarLetters = getAvatar(fullName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.cardDark : const Color(0xFFE5F3FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: PopupMenuButton<String>(
        tooltip: 'الملف الشخصي والحسابات',
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: bg,
        elevation: 8,
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: (userAvatar != null && userAvatar.trim().isNotEmpty)
              ? NetworkImage(userAvatar.trim())
              : null,
          child: (userAvatar == null || userAvatar.trim().isEmpty)
              ? Text(
                  avatarLetters,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        itemBuilder: (menuContext) => [
          // 1. الملف الشخصي (Profile)
          _buildMenuItem(
            value: 'profile',
            label: 'الملف الشخصي',
            icon: Icons.person_outline,
            isDark: isDark,
          ),
          // 2. تعديل الملف الشخصي (Edit Profile)
          _buildMenuItem(
            value: 'edit_profile',
            label: 'تعديل الملف الشخصي',
            icon: Icons.edit_outlined,
            isDark: isDark,
          ),
          // 3. إضافة حساب جديد (Add New Account)
          _buildMenuItem(
            value: 'add_account',
            label: 'إضافة حساب جديد',
            icon: Icons.add_rounded,
            isDark: isDark,
          ),
          // 4. تسجيل الخروج (Logout)
          _buildMenuItem(
            value: 'logout',
            label: 'تسجيل الخروج',
            icon: Icons.logout_rounded,
            isDark: isDark,
            isDanger: true,
          ),
        ],
        onSelected: (value) async {
          if (value == 'profile') {
            context.go(AppRoutes.profile);
          } else if (value == 'edit_profile') {
            context.push(AppRoutes.profileEdit);
          } else if (value == 'add_account') {
            await SwitchAccountsSheet.show(context);
          } else if (value == 'logout') {
            final confirm = await ConfirmationDialog.show(
              context: context,
              title: 'تسجيل الخروج',
              content: 'هل أنت متأكد من تسجيل الخروج؟',
              confirmLabel: 'تسجيل الخروج',
              confirmColor: Colors.red,
            );
            if (confirm && context.mounted) {
              await context.read<AuthProvider>().signOut();
            }
          }
        },
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isDanger = false,
  }) {
    final textColor = isDanger
        ? Colors.red
        : (isDark ? Colors.white : AppColors.textPrimary);

    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 18,
            color: isDanger
                ? Colors.red
                : (isDark ? Colors.white70 : AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
