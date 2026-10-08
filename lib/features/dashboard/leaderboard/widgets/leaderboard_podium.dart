import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'leaderboard_helpers.dart';

class LeaderboardPodiumWidget extends StatelessWidget {
  final List<Map<String, dynamic>> topThree;
  final ValueChanged<Map<String, dynamic>>? onUserTap;
  final String? currentUserId;

  const LeaderboardPodiumWidget({
    super.key,
    required this.topThree,
    this.onUserTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = AppTokens.isDesktop(context);

    final rank1 = topThree.firstWhere(
      (e) => e['rank'] == 1,
      orElse: () => topThree.first,
    );
    final rank2 = topThree.firstWhere(
      (e) => e['rank'] == 2,
      orElse: () => (topThree.length > 1 ? topThree[1] : topThree.first),
    );
    final rank3 = topThree.firstWhere(
      (e) => e['rank'] == 3,
      orElse: () => (topThree.length > 2 ? topThree[2] : topThree.first),
    );

    final p1Height = isDesktop ? 235.0 : 190.0;
    final p1Width = isDesktop ? 125.0 : 95.0;

    final p2Height = isDesktop ? 200.0 : 165.0;
    final p2Width = isDesktop ? 115.0 : 85.0;

    final p3Height = isDesktop ? 175.0 : 145.0;
    final p3Width = isDesktop ? 105.0 : 80.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank #3 Pedestal (Rightmost in RTL, visually #3 on Right)
          if (topThree.length >= 3)
            _buildPedestal(
              context: context,
              data: rank3,
              rank: 3,
              height: p3Height,
              width: p3Width,
              avatarRadius: isDesktop ? 26 : 22,
              isDark: isDark,
            ),
          SizedBox(width: isDesktop ? 16 : 10),

          // Rank #1 Pedestal (Center - Tallest & Largest)
          _buildPedestal(
            context: context,
            data: rank1,
            rank: 1,
            height: p1Height,
            width: p1Width,
            avatarRadius: isDesktop ? 36 : 28,
            isDark: isDark,
          ),
          SizedBox(width: isDesktop ? 16 : 10),

          // Rank #2 Pedestal (Leftmost in RTL, visually #2 on Left)
          if (topThree.length >= 2)
            _buildPedestal(
              context: context,
              data: rank2,
              rank: 2,
              height: p2Height,
              width: p2Width,
              avatarRadius: isDesktop ? 30 : 24,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildPedestal({
    required BuildContext context,
    required Map<String, dynamic> data,
    required int rank,
    required double height,
    required double width,
    required double avatarRadius,
    required bool isDark,
  }) {
    final rawAvatarUrl = data['avatar_url'] as String?;
    final avatarUpdatedAt = data['avatar_updated_at'] as String?;
    final avatarUrl = rawAvatarUrl != null && avatarUpdatedAt != null
        ? '$rawAvatarUrl?v=${DateTime.parse(avatarUpdatedAt).millisecondsSinceEpoch}'
        : rawAvatarUrl;
    final fullName = data['full_name'] as String? ?? 'طالبنا';
    final shortName = shortenFullName(fullName);
    final avatarLetters = getAvatar(fullName);
    final score = (data['total_score'] as num?)?.toInt() ?? 0;

    // Highlight the current user's pedestal instead of always highlighting #1.
    final isMe =
        currentUserId != null && data['user_id'] == currentUserId;

    final bg = isDark ? AppColors.cardDark : const Color(0xFFE5F3FF);

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '$fullName\nالمركز #$rank • $score نقطة',
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => onUserTap?.call(data),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.blue.withValues(alpha: isDark ? 0.18 : 0.12)
                      : bg,
                  borderRadius: BorderRadius.circular(24),
                  border: isMe
                      ? Border.all(color: AppColors.blue, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 6.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Avatar (No Cup/Trophy Icon)
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                          ? NetworkImage(avatarUrl.trim())
                          : null,
                      child: (avatarUrl == null || avatarUrl.trim().isEmpty)
                          ? Text(
                              avatarLetters,
                              style: TextStyle(
                                fontSize: avatarRadius * 0.65,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),

                    // Middle: Score Points Number Only (Name hidden until hover/tap)
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: width < 100 ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),

                    // Bottom: Rank Number (#1, #2, #3)
                    Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: width < 100 ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isMe ? 'أنت' : shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMe || rank == 1 ? 14 : 12.5,
              fontWeight: FontWeight.w800,
              color: isMe
                  ? AppColors.blue
                  : (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
