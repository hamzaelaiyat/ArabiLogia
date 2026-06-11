import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.username,
    required this.grade,
    this.avatarUrl,
    required this.isUploading,
    this.canUpload = true,
    required this.onPickImage,
    this.onRemoveAvatar,
  });

  final String name;
  final String username;
  final String grade;
  final String? avatarUrl;
  final bool isUploading;
  final bool canUpload;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveAvatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AvatarSection(
          avatarUrl: avatarUrl,
          name: name,
          isUploading: isUploading,
          canUpload: canUpload,
          onPickImage: onPickImage,
          onRemoveAvatar: onRemoveAvatar,
        ),
        const SizedBox(height: AppTokens.spacing16),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '@$username',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedColor(context),
          ),
        ),
        const SizedBox(height: AppTokens.spacing8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
          child: Text(
            grade,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.avatarUrl,
    required this.name,
    required this.isUploading,
    this.canUpload = true,
    required this.onPickImage,
    this.onRemoveAvatar,
  });

  final String? avatarUrl;
  final String name;
  final bool isUploading;
  final bool canUpload;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveAvatar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: canUpload ? onPickImage : null,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: canUpload ? 0.2 : 0.08),
                width: 4,
              ),
              boxShadow: null,
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surface(context),
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0] : '؟',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: canUpload ? AppColors.primary : AppColors.mutedColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  : null,
            ),
          ),
        ),
        if (isUploading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (canUpload)
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: onPickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (avatarUrl != null && onRemoveAvatar != null && !isUploading)
          Positioned(
            bottom: 4,
            left: 4,
            child: GestureDetector(
              onTap: onRemoveAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
