import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/solid_bottom_sheet.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.radiusLgAll,
        side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: AppTokens.radiusLgAll,
        onTap: () => _showDeleteConfirmation(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppTokens.spacing6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 20),
              SizedBox(width: AppTokens.spacing4),
              Text(
                'حذف الحساب نهائياً',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTokens.fontSizeMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    SolidBottomSheet.show(
      context: context,
      title: 'حذف الحساب',
      message: 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف الحساب',
      cancelLabel: 'إلغاء',
      confirmColor: Colors.red,
      onConfirm: () async {
        await context.read<AuthProvider>().signOut();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
    );
  }
}
