import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/models/account.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/accounts_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

class SwitchAccountsSheet extends StatefulWidget {
  const SwitchAccountsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const SwitchAccountsSheet(),
    );
  }

  @override
  State<SwitchAccountsSheet> createState() => _SwitchAccountsSheetState();
}

class _SwitchAccountsSheetState extends State<SwitchAccountsSheet> {
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().loadAccounts();
    });
  }

  Future<void> _switchTo(SavedAccount account) async {
    if (_isSwitching) return;
    setState(() => _isSwitching = true);

    final accountsProvider = context.read<AccountsProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentId = authProvider.state.user?.id;

    if (currentId == account.id) {
      Navigator.pop(context);
      return;
    }

    final success = await accountsProvider.switchToAccount(account, context);

    if (!mounted) return;
    setState(() => _isSwitching = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('مرحباً بعودتك، ${account.fullName}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تبديل الحساب')),
      );
    }
  }

  Future<void> _addAccount() async {
    final accountsProvider = context.read<AccountsProvider>();

    if (accountsProvider.hasReachedMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لقد وصلت إلى الحد الأقصى من الحسابات (8)')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await accountsProvider.saveCurrentSession(authProvider);
    await authProvider.signOut();

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _removeAccount(SavedAccount account) {
    if (context.read<AuthProvider>().state.user?.id == account.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إزالة الحساب الحالي')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إزالة الحساب'),
          content: Text('هل أنت متأكد من إزالة حساب "${account.fullName}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AccountsProvider>().removeAccount(account);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('إزالة'),
            ),
          ],
        ),
      ),
    );
  }

  String _getGradeText(int grade) {
    switch (grade) {
      case 10: return 'الأولى باكالوريا';
      case 11: return 'الثانية ثانوي';
      case 12: return 'الثالثة ثانوي';
      default: return 'صفك الدراسي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final accountsProvider = context.watch<AccountsProvider>();
    final currentUserId = authProvider.state.user?.id;
    final hasBlur = potato.blurEffectsEnabled;

    final container = Container(
      decoration: BoxDecoration(
        color: hasBlur
            ? AppColors.glassBackgroundColor(context).withValues(alpha: 0.8)
            : AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: hasBlur
            ? Border(
                top: BorderSide(
                  color: AppColors.glassBorderColor(context),
                  width: 1.5,
                ),
              )
            : null,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppTokens.spacing24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.spacing12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              borderRadius: AppTokens.radiusFullAll,
            ),
          ),
          const SizedBox(height: AppTokens.spacing24),
          Text(
            'تبديل الحساب',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : null,
            ),
          ),
          const SizedBox(height: AppTokens.spacing8),
          Text(
            'اختر حساباً للتبديل إليه',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacing16),
          if (accountsProvider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacing16),
                itemCount: accountsProvider.accounts.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final account = accountsProvider.accounts[index];
                  final isCurrent = account.id == currentUserId;
                  return _AccountTile(
                    account: account,
                    isCurrent: isCurrent,
                    gradeText: _getGradeText(account.grade),
                    isSwitching: _isSwitching,
                    onTap: () => _switchTo(account),
                    onRemove: () => _removeAccount(account),
                  );
                },
              ),
            ),
          if (!accountsProvider.hasReachedMax) ...[
            const SizedBox(height: AppTokens.spacing12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacing16),
              child: TextButton.icon(
                onPressed: _addAccount,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                  'إضافة حساب جديد (${accountsProvider.remainingSlots} متبقي)',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (hasBlur) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: container,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: container,
    );
  }
}

class _AccountTile extends StatelessWidget {
  final SavedAccount account;
  final bool isCurrent;
  final String gradeText;
  final bool isSwitching;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _AccountTile({
    required this.account,
    required this.isCurrent,
    required this.gradeText,
    required this.isSwitching,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isSwitching ? 0.5 : 1.0,
      child: ListTile(
        onTap: isSwitching ? null : onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.surface(context),
              backgroundImage: account.avatarUrl != null
                  ? NetworkImage(account.avatarUrl!)
                  : null,
              child: account.avatarUrl == null
                  ? Text(
                      account.fullName.isNotEmpty
                          ? account.fullName[0]
                          : '?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (isCurrent)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          account.fullName.isNotEmpty ? account.fullName : account.email,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? AppColors.primary : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '@${account.username}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedColor(context),
              ),
            ),
            if (account.grade > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Text(
                  gradeText,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isCurrent
            ? null
            : IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
                onPressed: onRemove,
              ),
      ),
    );
  }
}
