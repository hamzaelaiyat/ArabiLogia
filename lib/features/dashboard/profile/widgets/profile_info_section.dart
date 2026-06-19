import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ProfileInfoSection extends StatelessWidget {
  const ProfileInfoSection({
    super.key,
    required this.email,
    required this.registrationDate,
    required this.lastExamLabel,
  });

  final String email;
  final String registrationDate;
  final String lastExamLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            'معلومات الحساب',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppTokens.radius2xlAll,
          ),
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.email_outlined,
                title: 'البريد الإلكتروني',
                value: email,
              ),
              _InfoTile(
                icon: Icons.calendar_today_outlined,
                title: 'تاريخ التسجيل',
                value: registrationDate,
              ),
              _InfoTile(
                icon: Icons.history,
                title: 'آخر امتحان',
                value: lastExamLabel,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: AppTokens.radiusMdAll,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.mutedColor(context),
              ),
            ),
            subtitle: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
      ],
    );
  }
}
