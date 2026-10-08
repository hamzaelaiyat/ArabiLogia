import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';

/// Students of the exam's grade who have no completed attempt yet.
class ExamNonParticipantsList extends StatelessWidget {
  final List<Map<String, dynamic>> nonParticipants;

  const ExamNonParticipantsList({super.key, required this.nonParticipants});

  @override
  Widget build(BuildContext context) {
    if (nonParticipants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Text(
            'جميع الطلاب في هذا الصف أتموا الامتحان.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedColor(context)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.spacing12),
      itemCount: nonParticipants.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing8),
      itemBuilder: (context, index) {
        final profile = nonParticipants[index];
        return Card(
          elevation: AppTokens.elevationNone,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.radiusMdAll),
          color: AppColors.surface(context),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing12,
              vertical: AppTokens.spacing2,
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.surface(context),
              child: Icon(
                Icons.person_outline,
                color: AppColors.mutedColor(context),
              ),
            ),
            title: Text(
              profile['full_name'] ?? profile['username'] ?? 'مستخدم مجهول',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'الصف: ${getGradeText(profile['grade'])} • @${profile['username'] ?? '—'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTokens.fontSizeSm,
                color: AppColors.mutedColor(context),
              ),
            ),
          ),
        );
      },
    );
  }
}
