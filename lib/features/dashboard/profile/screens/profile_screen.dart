import 'dart:io';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/routes/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:arabilogia/core/widgets/glass_app_bar.dart';

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
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final file = File(image.path);
      final extension = p.extension(image.path);
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final path = fileName;

      await supabase.storage.from('avatars').upload(path, file);

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);

      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(avatarUrl: publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في رفع الصورة: $e')));
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
    final avatarUrl = user?.userMetadata?['avatar_url'];
    final email = user?.email ?? '---';
    final grade = user?.userMetadata?['grade'];
    final gradeText = _getGradeText(grade);
    final createdAt = user?.createdAt != null
        ? _formatArabicDate(user!.createdAt)
        : '---';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  child: _buildProfileHeader(
                    context,
                    fullName,
                    username,
                    gradeText,
                    avatarUrl,
                    potato.shadowsEnabled,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing32),
                AnimatedWrapper(
                  child: _buildStatsGrid(context, potato.shadowsEnabled),
                ),
                const SizedBox(height: AppTokens.spacing32),
                AnimatedWrapper(
                  child: _buildInfoSection(context, email, createdAt),
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

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String username,
    String grade,
    String? avatarUrl,
    bool shadowsEnabled,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 4,
                  ),
                  boxShadow: shadowsEnabled
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.surface(context),
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0] : '؟',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      : null,
                ),
              ),
            ),
            if (_isUploading)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _pickAndUploadImage,
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
          ],
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

  Widget _buildStatsGrid(BuildContext context, bool shadowsEnabled) {
    // Use fallback keys for compatibility with different backend responses
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

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppTokens.radius2xlAll,
        boxShadow: shadowsEnabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            '$examsCompleted',
            'امتحانات',
            Icons.assignment_outlined,
          ),
          _buildStatDivider(),
          _buildStatItem(
            context,
            '${((avgScore as num).toInt())}%',
            'المتوسط',
            Icons.analytics_outlined,
          ),
          _buildStatDivider(),
          _buildStatItem(
            context,
            '${((totalScore as num).toInt())}',
            'نقاط',
            Icons.emoji_events_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.primary.withValues(alpha: 0.1),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildInfoSection(BuildContext context, String email, String date) {
    final lastExam = _stats['last_exam'] as Map<String, dynamic>?;
    final lastExamSubject = lastExam?['subject'] ?? 'لا يوجد';
    final lastExamTime = _formatLastExamDate(lastExam?['created_at']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            'معلومات الحساب',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppTokens.radius2xlAll,
          ),
          child: Column(
            children: [
              _buildInfoTile(
                context,
                Icons.email_outlined,
                'البريد الإلكتروني',
                email,
              ),
              _buildInfoTile(
                context,
                Icons.calendar_today_outlined,
                'تاريخ التسجيل',
                date,
              ),
              _buildInfoTile(
                context,
                Icons.history,
                'آخر امتحان',
                lastExamSubject != 'لا يوجد'
                    ? '$lastExamSubject ($lastExamTime)'
                    : lastExamTime,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background(context),
              borderRadius: AppTokens.radiusMdAll,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.mutedColor(context),
            ),
          ),
          subtitle: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
      ],
    );
  }
}
