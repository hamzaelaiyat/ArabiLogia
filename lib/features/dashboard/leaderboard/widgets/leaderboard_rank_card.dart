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

  @override
  Widget build(BuildContext context) {
    final isBadged = leader['has_bad_tag'] == true;

    final rawAvatarUrl = leader['avatar_url'] as String?;
    final avatarUpdatedAt = leader['avatar_updated_at'] as String?;
    final avatarUrl = rawAvatarUrl != null && avatarUpdatedAt != null
        ? '$rawAvatarUrl?v=${DateTime.parse(avatarUpdatedAt).millisecondsSinceEpoch}'
        : rawAvatarUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing8),
      child: Card(
        color: null,
        shape: isMe
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing8),
          child: Row(
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
              const SizedBox(width: AppTokens.spacing8),
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          avatarLetters,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primary,
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
              Text(
                '${(leader['total_score'] as num).toInt()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isMe ? AppColors.primary : AppColors.primary,
                  fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
