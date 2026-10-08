import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';

/// Students who completed the exam, ranked by score so a teacher reads the
/// class top-down. Tapping a row opens a per-student detail sheet.
class ExamParticipantsList extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final ValueChanged<Map<String, dynamic>> onParticipantTap;

  const ExamParticipantsList({
    super.key,
    required this.participants,
    required this.onParticipantTap,
  });

  /// Scores are ranked, but rows missing a score sort last rather than throw.
  static List<Map<String, dynamic>> ranked(List<Map<String, dynamic>> rows) {
    final sorted = [...rows];
    sorted.sort((a, b) => _scoreOf(b).compareTo(_scoreOf(a)));
    return sorted;
  }

  static double _scoreOf(Map<String, dynamic> row) =>
      (row['score'] as num?)?.toDouble() ?? -1;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Text(
            'لم يقم أي طالب بأداء هذا الامتحان بعد.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedColor(context)),
          ),
        ),
      );
    }

    final sorted = ranked(participants);

    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.spacing12),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing8),
      itemBuilder: (context, index) {
        final result = sorted[index];
        final profile = result['profile'] as Map<String, dynamic>?;
        final score = _scoreOf(result);
        final passed = score >= 50;
        final points = (result['points'] as num?)?.toInt();
        final createdAt = result['created_at'] as String?;

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
              backgroundColor: passed ? AppColors.success : AppColors.error,
              child: Text(
                score < 0 ? '--' : score.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTokens.fontSizeSm,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              profile?['full_name'] ?? profile?['username'] ?? 'مستخدم مجهول',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                '@${profile?['username'] ?? '—'}',
                getGradeText(profile?['grade']),
                if (createdAt != null)
                  intl.DateFormat(
                    'dd/MM HH:mm',
                  ).format(DateTime.parse(createdAt).toLocal()),
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTokens.fontSizeSm,
                color: AppColors.mutedColor(context),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  passed ? 'ناجح' : 'راسب',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeXs,
                    fontWeight: FontWeight.w600,
                    color: passed ? AppColors.success : AppColors.error,
                  ),
                ),
                if (points != null && points > 0)
                  Text(
                    '+$points نقطة',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeXs,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            onTap: () => onParticipantTap(result),
          ),
        );
      },
    );
  }
}
