import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ProfileHeroCard extends StatelessWidget {
  final String name;
  final String username;
  final String email;
  final String grade;
  final String? avatarUrl;
  final bool isUploading;
  final bool canUpload;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveAvatar;

  final int totalScore;
  final int rank;
  final int improvementPercentage;

  const ProfileHeroCard({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.grade,
    this.avatarUrl,
    required this.isUploading,
    this.canUpload = true,
    required this.onPickImage,
    this.onRemoveAvatar,
    required this.totalScore,
    required this.rank,
    required this.improvementPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = AppTokens.isDesktop(context);

    final cardBg = isDark ? AppColors.cardDark : const Color(0xFFE5F3FF);

    return Semantics(
      label: 'الملف الشخصي لـ $name، $grade، $totalScore نقطة، المركز $rank',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
        child: isDesktop
            ? _buildDesktopLayout(context, isDark)
            : _buildMobileLayout(context, isDark),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1st Child in RTL Row: Large Avatar Circle (Placed on the RIGHT Side)
        _buildAvatarCircle(context, isDark, radius: 65),
        const SizedBox(width: 28),

        // 2nd Child in RTL Row: Name, Grade, Email & Stats Row (Placed on the LEFT Side)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Student Name
              Text(
                name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Grade & Email
              Row(
                children: [
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.mutedDark : AppColors.textMuted,
                    ),
                  ),
                  if (email.isNotEmpty && email != '---') ...[
                    const SizedBox(width: 12),
                    Text(
                      '• $email',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.mutedDark
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // 3 Stats Items Row
              _buildStatsRow(context, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Centered Avatar
        _buildAvatarCircle(context, isDark, radius: 50),
        const SizedBox(height: 14),

        // Student Name
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Grade
        Text(
          grade,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.mutedDark : AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // 3 Stats Items Row
        _buildStatsRow(context, isDark),
      ],
    );
  }

  Widget _buildAvatarCircle(
    BuildContext context,
    bool isDark, {
    required double radius,
  }) {
    final avatarBg = isDark ? const Color(0xFF263852) : const Color(0xFF97CBFF);

    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
          child: isUploading
              ? const Center(child: CircularProgressIndicator())
              : ClipOval(
                  child: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                      ? Image.network(
                          avatarUrl!.trim(),
                          width: radius * 2,
                          height: radius * 2,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildAvatarLetters(radius),
                        )
                      : _buildAvatarLetters(radius),
                ),
        ),

        // Floating 3-dots Action Menu Button at bottom-left of avatar
        if (canUpload)
          Positioned(
            bottom: 0,
            left: 0,
            child: PopupMenuButton<String>(
              tooltip: 'خيارات الصورة',
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: isDark ? AppColors.cardDark : Colors.white,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.textPrimary
                      : const Color(0xFF70B5FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'upload',
                  child: Row(
                    children: [
                      Icon(Icons.photo_camera_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('تغيير الصورة'),
                    ],
                  ),
                ),
                if (avatarUrl != null && onRemoveAvatar != null)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف الصورة', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'upload') {
                  onPickImage();
                } else if (value == 'remove') {
                  onRemoveAvatar?.call();
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarLetters(double radius) {
    final letters = name.isNotEmpty ? name[0] : '؟';
    return Center(
      child: Text(
        letters,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Stat 1: معاك حالياً (Score)
        _buildStatItem(
          title: 'معاك حالياً',
          valueWidget: Text(
            '$totalScore',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          subtitle: 'نقطة',
          isDark: isDark,
        ),

        // Stat 2: ترتيبك (Rank)
        _buildStatItem(
          title: 'ترتيبك',
          valueWidget: Text(
            rank > 0 ? '$rank' : '---',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          subtitle: 'علي الدفعة',
          isDark: isDark,
        ),

        // Stat 3: اتحسنت (Improvement)
        _buildStatItem(
          title: 'اتحسنت',
          valueWidget: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$improvementPercentage',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                WidgetSpan(
                  child: Transform.translate(
                    offset: const Offset(-2, -10),
                    child: Text(
                      '%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          subtitle: 'عن اخر شهر',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required Widget valueWidget,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.mutedDark : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget,
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.mutedDark : AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
