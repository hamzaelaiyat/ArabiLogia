import 'dart:io' show Platform, File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:arabilogia/core/utils/auth_error_mapper.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_header.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_stats_grid.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/profile_info_section.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/core/widgets/responsive_app_bar_title.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  final ScoreRepository _scoreRepository = ScoreRepository();
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
  bool _isLoadingStats = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouter.routeObserver.subscribe(this, ModalRoute.of(context)!);
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
      final stats = await _scoreRepository.getDetailedProfileStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
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

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    String imagePath = image.path;

    // Platform-specific cropping: use image_cropper for Android/iOS/Web, auto-center-crop for desktop
    final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
    if (!isDesktop) {
      // Crop to 1:1 aspect ratio using native cropper
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'اقتصاص الصورة',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'اقتصاص الصورة',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
            initialAspectRatio: 1,
            checkOrientation: true,
            rotatable: true,
            scalable: true,
            zoomable: true,
          ),
        ],
      );

      if (croppedFile == null) return;
      imagePath = croppedFile.path;
    } else {
      // Desktop: auto center-crop to 1:1
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري تجهيز الصورة...')),
        );
      }
      final file = File(image.path);
      final originalBytes = await file.readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('غير قادر على قراءة الصورة')),
          );
        }
        return;
      }
      // Center crop to 1:1
      final size = decoded.width < decoded.height ? decoded.width : decoded.height;
      final x = (decoded.width - size) ~/ 2;
      final y = (decoded.height - size) ~/ 2;
      final cropped = img.copyCrop(decoded, x: x, y: y, width: size, height: size);
      final croppedBytes = Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(croppedBytes);
      imagePath = tempFile.path;
    }

    setState(() => _isUploading = true);

    try {
      final file = File(imagePath);
      final originalBytes = await file.readAsBytes();

      // Decode and resize to 100x100 before size validation
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('غير قادر على قراءة الصورة')),
          );
        }
        return;
      }
      final resized = img.copyResize(decoded, width: 100, height: 100);
      final resizedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

      // Validate file size after resize (50KB limit — enforced server-side too)
      if (resizedBytes.length > 50 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حجم الصورة كبير جداً (الحد الأقصى 50 كيلوبايت)'),
            ),
          );
        }
        return;
      }

      // Upload via Edge Function
      final result = await authProvider.uploadAvatar(resizedBytes);

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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إزالة الصورة الشخصية'),
          content: const Text('هل أنت متأكد من إزالة صورتك الشخصية؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('إزالة'),
            ),
          ],
        ),
      ),
    ) ?? false;

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

  void _showEditProfileDialog() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.state.user;
    final nameController = TextEditingController(
      text: user?.userMetadata?['full_name'],
    );
    final usernameController = TextEditingController(
      text: user?.userMetadata?['username'],
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الملف الشخصي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final scaffold = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);

                final success = await authProvider.updateProfile(
                  fullName: nameController.text.trim(),
                  username: usernameController.text.trim(),
                );

                if (success) {
                  scaffold.showSnackBar(
                    const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
                  );
                  nav.pop();
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final potato = context.watch<PotatoModeProvider>();
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
    final gradeText = _getGradeText(grade);
    final createdAt = user?.createdAt != null
        ? _formatArabicDate(user!.createdAt)
        : '---';

    final lastExam = _stats['last_exam'] as Map<String, dynamic>?;
    final lastExamSubject = lastExam?['subject'] ?? 'لا يوجد';
    final lastExamTime = _formatLastExamDate(lastExam?['created_at']);
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
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGradeText(dynamic grade) {
    if (grade == null) return 'رحلتك الدراسية';
    final g = grade is int ? grade : int.tryParse(grade.toString()) ?? 0;
    switch (g) {
      case 10:
        return 'الأولى باكالوريا';
      case 11:
        return 'الثانية ثانوي';
      case 12:
        return 'الثالثة ثانوي';
      default:
        return 'صفك الدراسي';
    }
  }

  String _formatArabicDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  String _formatLastExamDate(String? isoDate) {
    if (isoDate == null) return 'لم تؤدِّ أي امتحان بعد';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';

      return _formatArabicDate(isoDate);
    } catch (e) {
      return isoDate ?? '';
    }
  }

}
