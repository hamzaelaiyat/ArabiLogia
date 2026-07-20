import 'package:flutter/material.dart';
import 'package:arabilogia/core/models/account.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class AccountTile extends StatelessWidget {
  final SavedAccount account;
  final bool isCurrent;
  final String gradeText;
  final bool isSwitching;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const AccountTile({
    super.key,
    required this.account,
    required this.isCurrent,
    required this.gradeText,
    required this.isSwitching,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isSwitching ? 0.5 : 1.0,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: isSwitching ? null : onTap,
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.surface(context),
                child: account.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          account.avatarUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                account.fullName.isNotEmpty ? account.fullName[0] : '?',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        account.fullName.isNotEmpty ? account.fullName[0] : '?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
      ),
    );
  }
}
