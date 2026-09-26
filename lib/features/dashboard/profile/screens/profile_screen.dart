import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/core/widgets/animated_wrapper.dart';
import 'package:arabilogia/features/dashboard/leaderboard/repositories/leaderboard_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_hero_card.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_lecture_progress_chart.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';
import 'package:arabilogia/features/dashboard/profile/services/avatar_picker_service.dart';
import 'package:arabilogia/features/dashboard/profile/screens/image_editor_screen.dart';
import 'package:arabilogia/core/utils/arabic_date_formatter.dart';
import 'package:arabilogia/core/utils/grade_utils.dart';
import 'package:arabilogia/core/widgets/confirmation_dialog.dart';
import 'package:arabilogia/core/widgets/error_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();
  final ScoreRepository _scoreRepository = ScoreRepository();

  Map<String, dynamic> _stats = {
    'exams_count': 0,
    'exams_completed': 0,
    'avg_score': 0,
    'average_score': 0,
    'total_points': 0,
    'total_score': 0,
    'rank': 0,
    'last_exam': null,
  };
  List<double> _progressPoints = [];
  int _improvementPercentage = 0;
  bool _isUploading = false;
  bool _hasError = false;
  final AvatarPickerService _avatarPickerService = AvatarPickerService();

  @override
  void initState() {
    super.initState();
    _fetchData();
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
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final stats = await _leaderboardRepository.getDetailedProfileStats();
      final scoresHistory = await _scoreRepository.getStudentScoresHistory();

      List<double> points = [];
      if (scoresHistory.isNotEmpty) {
        points = scoresHistory
            .map((e) => ((e['score'] as num?)?.toDouble() ?? 0.0) / 100.0)
            .toList();
        if (points.length >= 2) {
          final first = points.first;
          final last = points.last;
          if (first > 0) {
            _improvementPercentage = (((last - first) / first) * 100).round();
          }
        }
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _progressPoints = points;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile stats: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.canUploadAvatar) {
      if (mounted) {
        final msg = authProvider.hasBadTag
            ? 'تم حظر رفع الصور بشكل دائم'
            : 'محظور مؤقتاً. يرجى المحاولة لاحقاً';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else if (code == 'PERMANENT_BLOCKED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حظر رفع الصور بشكل دائم')),
        );
      } else if (code == 'TEMPORARILY_BLOCKED') {
        final msg = result['error'] as String? ?? 'محظور مؤقتاً';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else if (code == 'SCAN_FAILED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فحص الصورة، حاول مرة أخرى')),
        );
      } else if (code == 'INVALID_FILE') {
        final msg = result['error'] as String? ?? 'الملف غير صالح';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else if (code == 'NETWORK_ERROR') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ في رفع الصورة')));
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = getArabicStorageError(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
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
          SnackBar(
            content: Text(authProvider.state.error ?? 'خطأ في إزالة الصورة'),
          ),
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
    final gradeText = getGradeText(grade, fallback: 'صفك الدراسي');
    final createdAt = user?.createdAt != null
        ? formatArabicDate(user!.createdAt)
        : '---';

    final lastExam = _stats['last_exam'] as Map<String, dynamic>?;
    final lastExamSubject = lastExam?['subject'] ?? 'لا يوجد';
    final lastExamTime = formatLastExamDate(lastExam?['created_at']);
    final lastExamLabel = lastExamSubject != 'لا يوجد'
        ? '$lastExamSubject ($lastExamTime)'
        : lastExamTime;

    final totalScore =
        (_stats['total_score'] ??
                _stats['total_points'] ??
                _stats['points'] ??
                0)
            as int;
    final rank = (_stats['rank'] ?? 0) as int;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.profileScreen,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(title: ResponsiveAppBarTitle('الملف الشخصي')),
        body: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top:
                  MediaQuery.paddingOf(context).top +
                  kToolbarHeight +
                  AppTokens.spacing16,
              left: AppTokens.spacing16,
              right: AppTokens.spacing16,
              bottom: AppTokens.spacing24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Profile Card (#E5F3FF container matching screenshot)
                AnimatedWrapper(
                  delay: Duration.zero,
                  child: ProfileHeroCard(
                    name: fullName,
                    username: username,
                    email: email,
                    grade: gradeText,
                    avatarUrl: avatarUrl,
                    isUploading: _isUploading,
                    canUpload: authProvider.canUploadAvatar,
                    onPickImage: _pickAndUploadImage,
                    onRemoveAvatar: avatarUrl != null ? _removeAvatar : null,
                    totalScore: totalScore,
                    rank: rank,
                    improvementPercentage: _improvementPercentage,
                  ),
                ),
                const SizedBox(height: 24),

                // Account Information Lines (Email, Created Date, Last Activity)
                AnimatedWrapper(
                  delay: const Duration(milliseconds: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (email.isNotEmpty && email != '---') ...[
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'البريد الالكتروني: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: email),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                text: 'تم إنشاء الحساب: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: createdAt),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                text: 'آخر نشاط: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: lastExamLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_hasError)
                  ErrorState(
                    title: 'تعذر تحميل إحصائياتك',
                    detail: 'تحقق من اتصالك بالإنترنت ثم أعد المحاولة',
                    onRetry: _fetchData,
                  )
                else
                  // Lecture Progress Smooth Bézier Chart Card
                  AnimatedWrapper(
                    delay: const Duration(milliseconds: 80),
                    child: ProfileLectureProgressChartCard(
                      progressPoints: _progressPoints,
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
