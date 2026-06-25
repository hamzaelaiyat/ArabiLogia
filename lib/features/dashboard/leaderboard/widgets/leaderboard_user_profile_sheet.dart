import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:provider/provider.dart';
import 'leaderboard_helpers.dart';

class LeaderboardUserProfileSheet extends StatelessWidget {
  final Map<String, dynamic> userData;

  const LeaderboardUserProfileSheet({
    super.key,
    required this.userData,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> userData,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => LeaderboardUserProfileSheet(userData: userData),
    );
  }

  Color _avatarColor(String userId) {
    final palette = [
      AppColors.primary,
      const Color(0xFFE53935),
      const Color(0xFF43A047),
      const Color(0xFF1E88E5),
      const Color(0xFF8E24AA),
      const Color(0xFFFF6F00),
      const Color(0xFF00ACC1),
      const Color(0xFFD81B60),
    ];
    return palette[userId.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final potato = context.watch<PotatoModeProvider>();
    final hasBlur = potato.blurEffectsEnabled;

    final userId = userData['user_id'] as String? ?? '';
    final fullName = userData['full_name'] as String? ?? '';
    final grade = userData['grade'];
    final gradeName = getGradeName(grade is int ? grade : int.tryParse(grade?.toString() ?? '') ?? 0);
    final avatarLetters = getAvatar(fullName);
    final rawAvatarUrl = userData['avatar_url'] as String?;
    final avatarUpdatedAt = userData['avatar_updated_at'] as String?;
    final avatarUrl = rawAvatarUrl != null && avatarUpdatedAt != null
        ? '$rawAvatarUrl?v=${DateTime.parse(avatarUpdatedAt).millisecondsSinceEpoch}'
        : rawAvatarUrl;
    final description = userData['description'] as String? ?? '';
    final examsCompleted = userData['exams_completed'] as num? ?? 0;
    final avgScore = userData['avg_score'] as num? ?? 0;
    final totalScore = userData['total_score'] as num? ?? 0;
    final rank = userData['rank'] as int? ?? 0;

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
      padding: const EdgeInsets.all(AppTokens.spacing24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              borderRadius: AppTokens.radiusFullAll,
            ),
          ),
          const SizedBox(height: AppTokens.spacing24),
          CircleAvatar(
            radius: 56,
            backgroundColor: _avatarColor(userId).withValues(alpha: 0.15),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            avatarLetters,
                            style: TextStyle(
                              color: _avatarColor(userId),
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                              height: 1.0,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      avatarLetters,
                      style: TextStyle(
                        color: _avatarColor(userId),
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        height: 1.0,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppTokens.spacing16),
          Text(
            fullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTokens.spacing4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            ),
            child: Text(
              gradeName,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacing16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTokens.spacing12),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: AppTokens.radiusXlAll,
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedColor(context),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spacing20),
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppTokens.radius2xlAll,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  value: '$examsCompleted',
                  label: 'امتحانات',
                  icon: Icons.assignment_outlined,
                ),
                _StatDivider(),
                _StatItem(
                  value: '${avgScore.toInt()}%',
                  label: 'المتوسط',
                  icon: Icons.analytics_outlined,
                ),
                _StatDivider(),
                _StatItem(
                  value: '${totalScore.toInt()}',
                  label: 'نقاط',
                  icon: Icons.emoji_events_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spacing16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppTokens.radiusXlAll,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'المرتبة #$rank',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spacing8),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.primary.withValues(alpha: 0.1),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.foreground(context),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.mutedColor(context),
          ),
        ),
      ],
    );
  }
}
