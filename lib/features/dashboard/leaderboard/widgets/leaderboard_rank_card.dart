import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class LeaderboardRankCard extends StatelessWidget {
  /// Total vertical space one card occupies, bottom margin included.
  /// Grid layouts size their rows from this so cards are never clipped.
  static const double cardExtent = _cardHeight + AppTokens.spacing12;

  static const double _cardHeight = 76;

  final Map<String, dynamic> leader;
  final bool isMe;
  final int rank;
  final bool isTopThree;
  final String gradeName;
  final String avatarLetters;
  final VoidCallback? onTap;

  const LeaderboardRankCard({
    super.key,
    required this.leader,
    required this.isMe,
    required this.rank,
    required this.isTopThree,
    required this.gradeName,
    required this.avatarLetters,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rawAvatarUrl = leader['avatar_url'] as String?;
    final avatarUpdatedAt = leader['avatar_updated_at'] as String?;
    final avatarUrl = rawAvatarUrl != null && avatarUpdatedAt != null
        ? '$rawAvatarUrl?v=${DateTime.parse(avatarUpdatedAt).millisecondsSinceEpoch}'
        : rawAvatarUrl;

    final fullName = leader['full_name'] as String? ?? 'طالبنا';
    final score = (leader['total_score'] as num?)?.toInt() ?? 0;

    // Requested #E5F3FF soft light blue background color matching target screenshot
    final cardBg = isDark ? AppColors.cardDark : const Color(0xFFE5F3FF);

    const isMeBlue = AppColors.blue;

    return Tooltip(
      message: '$fullName\nالمركز #$rank • $gradeName • $score نقطة',
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
      child: Semantics(
        label: '$fullName، المركز #$rank، $gradeName، $score نقطة',
        button: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
          height: _cardHeight,
          decoration: BoxDecoration(
            color: isMe ? isMeBlue.withValues(alpha: 0.12) : cardBg,
            borderRadius: BorderRadius.circular(24),
            border: isMe ? Border.all(color: isMeBlue, width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  // Far Right (in RTL): Avatar Image
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage:
                        (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                        ? NetworkImage(avatarUrl.trim())
                        : null,
                    child: (avatarUrl == null || avatarUrl.trim().isEmpty)
                        ? Text(
                            avatarLetters,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Middle: Full Name & Rank Badge #4
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Far Left (in RTL): Total Score Points Number
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
