import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/core/widgets/animated_wrapper.dart';
import 'package:arabilogia/features/dashboard/leaderboard/repositories/leaderboard_repository.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_header.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_stats_grid.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_info_section.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/switch_accounts_sheet.dart';
import 'package:arabilogia/features/dashboard/profile/providers/accounts_provider.dart';
import 'package:arabilogia/core/services/accounts_service.dart';
import 'package:arabilogia/features/dashboard/profile/services/avatar_picker_service.dart';
import 'package:arabilogia/features/dashboard/profile/screens/image_editor_screen.dart';
import 'package:arabilogia/core/utils/arabic_date_formatter.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';
import 'package:arabilogia/core/widgets/confirmation_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();
  Map<String, dynamic> _stats = {
    'exams_count': 0,
    'exams_completed': 0, // fallback
    'avg_score': 0,
    'average_score': 0, // fallback
    'total_points': 0,
    'total_score': 0, // fallback
    'rank': 0,
    'last_exam': null,
  };
  bool _isUploading = false;
  final AvatarPickerService _avatarPickerService = AvatarPickerService();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _leaderboardRepository.getDetailedProfileStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      // Stats will keep defaults on error
    }
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.canUploadAvatar) {
      if (mounted) {
        final msg = authProvider.hasBadTag
            ? 'تم حظر رفع الصور بشكل دائم'
            : 'محظور مؤقتاً. يرجى المحاولة لاحقاً';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }

    late final Uint8List bytes;
    try {
      final pickedBytes = await _avatarPickerService.pickBytes();
      if (pickedBytes == null) return;

      if (!mounted) return;
      final cropped = await ImageEditorScreen.show(context, pickedBytes);
      if (cropped == null) return;

      bytes = await _avatarPickerService.processCropped(cropped);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل اقتصاص الصورة: ${e.toString()}')),
        );
      }
      return;
    }

    if (bytes.length > 50 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حجم الصورة كبير جداً (الحد الأقصى 50 كيلوبايت)'),
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await authProvider.uploadAvatar(bytes);

      if (!mounted) return;

      final status = result['status'] as String?;
      final code = result['code'] as String?;

      if (status == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح')),
        );
      } else if (status == 'rejected') {
        final count = result['violationCount'] as int? ?? 0;
        final msg = count == 1
            ? 'إنذار: الصورة غير مناسبة. المخالفة التالية تؤدي إلى حظر 30 دقيقة'
            : count == 2
                ? 'تم حظر رفع الصور لمدة 30 دقيقة بسبب المخالفة'
                : 'تم حظر رفع الصور بشكل دائم بسبب المخالفات المتكررة';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else if (code == 'PERMANENT_BLOCKED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حظر رفع الصور بشكل دائم')),
        );
      } else if (code == 'TEMPORARILY_BLOCKED') {
        final msg = result['error'] as String? ?? 'محظور مؤقتاً';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else if (code == 'SCAN_FAILED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فحص الصورة، حاول مرة أخرى')),
        );
      } else if (code == 'INVALID_FILE') {
        final msg = result['error'] as String? ?? 'الملف غير صالح';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else if (code == 'NETWORK_ERROR') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في رفع الصورة')),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = getArabicStorageError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removeAvatar() async {
    final authProvider = context.read<AuthProvider>();

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'إزالة الصورة الشخصية',
      content: 'هل أنت متأكد من إزالة صورتك الشخصية؟',
      confirmLabel: 'إزالة',
      confirmColor: AppColors.error,
    );

    if (!confirmed) return;

    setState(() => _isUploading = true);

    try {
      final success = await authProvider.removeAvatar();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إزالة الصورة الشخصية بنجاح')),
        );
        authProvider.refreshUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.state.error ?? 'خطأ في إزالة الصورة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.state.user;
    final fullName = user?.userMetadata?['full_name'] ?? 'طالب عربيلوجيا';
    final username = user?.userMetadata?['username'] ?? 'user';
    final rawAvatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final avatarUpdatedAt = user?.userMetadata?['avatar_updated_at'] as String?;
    final avatarUrl = rawAvatarUrl != null && avatarUpdatedAt != null
        ? '$rawAvatarUrl?v=${DateTime.parse(avatarUpdatedAt).millisecondsSinceEpoch}'
        : rawAvatarUrl;
    final email = user?.email ?? '---';
    final grade = user?.userMetadata?['grade'];
    final gradeText = getGradeText(grade, fallback: 'رحلتك الدراسية');
    final description = user?.userMetadata?['description'] as String? ?? '';
    final createdAt = user?.createdAt != null
        ? formatArabicDate(user!.createdAt)
        : '---';

    final lastExam = _stats['last_exam'] as Map<String, dynamic>?;
    final lastExamSubject = lastExam?['subject'] ?? 'لا يوجد';
    final lastExamTime = formatLastExamDate(lastExam?['created_at']);
    final lastExamLabel = lastExamSubject != 'لا يوجد'
        ? '$lastExamSubject ($lastExamTime)'
        : lastExamTime;

    final examsCompleted =
        _stats['exams_completed'] ??
        _stats['exams_count'] ??
        _stats['total_exams'] ??
        0;
    final avgScore =
        _stats['avg_score'] ??
        _stats['average_score'] ??
        _stats['average'] ??
        0;
    final totalScore =
        _stats['total_score'] ??
        _stats['total_points'] ??
        _stats['points'] ??
        0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.profileScreen,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const ResponsiveAppBarTitle('الملف الشخصي'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.profileEdit),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top:
                  MediaQuery.paddingOf(context).top +
                  kToolbarHeight +
                  AppTokens.spacing24,
              left: AppTokens.spacing16,
              right: AppTokens.spacing16,
              bottom: AppTokens.spacing24,
            ),
            child: Column(
              children: [
                AnimatedWrapper(
                  delay: Duration.zero,
                  child: ProfileHeader(
                    name: fullName,
                    username: username,
                    grade: gradeText,
                    avatarUrl: avatarUrl,
                    isUploading: _isUploading,
                    canUpload: authProvider.canUploadAvatar,
                    onPickImage: _pickAndUploadImage,
                    onRemoveAvatar: avatarUrl != null ? _removeAvatar : null,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.spacing20),
                  AnimatedWrapper(
                    delay: const Duration(milliseconds: 40),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: AppTokens.radius2xlAll,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 20,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: AppTokens.spacing8),
                          Expanded(
                            child: Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.mutedColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.spacing32),
                AnimatedWrapper(
                  delay: const Duration(milliseconds: 80),
                  child: ProfileStatsGrid(
                    examsCompleted: examsCompleted,
                    avgScore: avgScore,
                    totalScore: totalScore,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing32),
                AnimatedWrapper(
                  delay: const Duration(milliseconds: 160),
                  child: ProfileInfoSection(
                    email: email,
                    registrationDate: createdAt,
                    lastExamLabel: lastExamLabel,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing32),
                AnimatedWrapper(
                  delay: const Duration(milliseconds: 240),
                  child: _SwitchAccountButton(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchAccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accountsProvider = context.watch<AccountsProvider>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radius2xlAll,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius2xlAll,
        child: InkWell(
          borderRadius: AppTokens.radius2xlAll,
          onTap: () => SwitchAccountsSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacing16,
              vertical: AppTokens.spacing16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppTokens.radiusLgAll,
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTokens.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تبديل الحساب',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${accountsProvider.accounts.length} من ${AccountsService.maxAccounts} حسابات',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: AppColors.mutedColor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
