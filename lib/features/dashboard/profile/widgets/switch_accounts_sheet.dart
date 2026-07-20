import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/models/account.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/dashboard/profile/providers/accounts_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/account_tile.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';
import 'package:arabilogia/core/widgets/confirmation_dialog.dart';

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
      if (mounted) {
        context.read<AccountsProvider>().loadAccounts();
      }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل تبديل الحساب')));
    }
  }

  Future<void> _addAccount() async {
    final accountsProvider = context.read<AccountsProvider>();

    if (accountsProvider.hasReachedMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لقد وصلت إلى الحد الأقصى من الحسابات (8)'),
        ),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'إضافة حساب جديد',
      content: 'سيتم تسجيل الخروج من الحساب الحالي للسماح لك بتسجيل الدخول بحساب آخر.',
      confirmLabel: 'تسجيل الخروج',
      confirmColor: AppColors.primary,
    );
    if (!confirmed) return;
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await accountsProvider.saveCurrentSession(authProvider);

    if (!mounted) return;
    Navigator.pop(context);

    await authProvider.signOut();
  }

  Future<void> _removeAccount(SavedAccount account) async {
    if (context.read<AuthProvider>().state.user?.id == account.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إزالة الحساب الحالي')),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'إزالة الحساب',
      content: 'هل أنت متأكد من إزالة حساب "${account.fullName}"؟',
      confirmLabel: 'إزالة',
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;
    if (!mounted) return;

    context.read<AccountsProvider>().removeAccount(account);
  }

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final accountsProvider = context.watch<AccountsProvider>();
    final currentUserId = authProvider.state.user?.id;
    final hasBlur = potato.blurEffectsEnabled;

    final container = Container(
      key: TestKeys.switchAccountsSheet,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacing16,
                ),
                itemCount: accountsProvider.accounts.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final account = accountsProvider.accounts[index];
                  final isCurrent = account.id == currentUserId;
                  return AccountTile(
                    account: account,
                    isCurrent: isCurrent,
                    gradeText: getGradeText(account.grade),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacing16,
              ),
              child: TextButton.icon(
                key: TestKeys.switchAccountsAdd,
                onPressed: _addAccount,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                  'إضافة حساب جديد (${accountsProvider.remainingSlots} متبقي)',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
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
