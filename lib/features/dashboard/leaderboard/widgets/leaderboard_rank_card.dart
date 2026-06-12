import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class LeaderboardRankCard extends StatelessWidget {
  final Map<String, dynamic> leader;
  final bool isMe;
  final int rank;
  final bool isTopThree;
  final String gradeName;
  final String avatarLetters;

  const LeaderboardRankCard({
    super.key,
    required this.leader,
    required this.isMe,
    required this.rank,
    required this.isTopThree,
    required this.gradeName,
    required this.avatarLetters,
  });

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
    final isBadged = leader['has_bad_tag'] == true;
    final userId = leader['user_id'] as String? ?? '';

    final rawAvatarUrl = leader['avatar_url'] as String?;
    final avatarUpdatedAt = leader['avatar_updated_at'] as String?;
    final avatarUrl = rawAvatarUrl != null && avatarUpdatedAt != null
        ? '$rawAvatarUrl?v=${DateTime.parse(avatarUpdatedAt).millisecondsSinceEpoch}'
        : rawAvatarUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        color: isMe ? AppColors.primary.withValues(alpha: 0.05) : null,
        elevation: isMe ? AppTokens.elevationMd : AppTokens.elevationSm,
        shape: isMe
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: AppTokens.radius2xlAll,
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing8),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppColors.primary
                          : AppColors.rankColor(rank, context),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${leader['rank']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMe || isTopThree
                              ? Colors.white
                              : AppColors.mutedColor(context),
                        ),
                      ),
                    ),
                  ),
                  if (rank == 1)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppTokens.spacing8),
              CircleAvatar(
                backgroundColor: _avatarColor(userId).withValues(alpha: 0.15),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          avatarLetters,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _avatarColor(userId),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.0,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTokens.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            leader['full_name'] ?? '',
                            style: (isBadged
                                    ? TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.red,
                                        decorationColor: Colors.red,
                                      )
                                    : isMe
                                        ? Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            )
                                        : null) ??
                                Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'أنت',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isBadged) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'مخالف - تم حظر رفع الصور',
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      gradeName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(leader['total_score'] as num).toInt()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isMe ? AppColors.primary : AppColors.primary,
                      fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                    ),
                  ),
                  Text(
                    'نقطة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedColor(context),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
