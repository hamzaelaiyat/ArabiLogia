import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/confirmation_dialog.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _descriptionController;
  int? _selectedGrade;
  DateTime? _gradeUpdatedAt;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.state.user;
    _nameController = TextEditingController(
      text: user?.userMetadata?['full_name'],
    );
    _usernameController = TextEditingController(
      text: user?.userMetadata?['username'],
    );
    _descriptionController = TextEditingController(
      text: user?.userMetadata?['description'],
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.state.user;
    if (user == null) {
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    try {
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('description')
          .eq('id', user.id)
          .single();
      if (profileResponse['description'] != null && mounted) {
        _descriptionController.text = profileResponse['description'] as String;
      }
    } catch (e) {
      debugPrint('Failed to load description: $e');
    }

    final gradeVal = user.userMetadata?['grade'];
    // Never guess: defaulting here silently moved students into whichever
    // grade happened to be hardcoded, so an absent value stays null and the
    // user has to choose explicitly.
    if (gradeVal is int) {
      _selectedGrade = gradeVal;
    } else if (gradeVal != null) {
      _selectedGrade = int.tryParse(gradeVal.toString());
    }

    if (!mounted) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('grade_updated_at')
          .eq('id', user.id)
          .single();
      if (mounted) {
        final rawDate = response['grade_updated_at'];
        setState(() {
          _gradeUpdatedAt = rawDate is String
              ? DateTime.tryParse(rawDate)
              : null;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load grade_updated_at: $e');
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isGradeLocked {
    if (_gradeUpdatedAt == null) return false;
    return DateTime.now().difference(_gradeUpdatedAt!).inDays < 3;
  }

  Future<void> _save() async {
    final authProvider = context.read<AuthProvider>();

    final user = authProvider.state.user;
    final currentGradeVal = user?.userMetadata?['grade'];
    final int currentGrade = currentGradeVal is int
        ? currentGradeVal
        : int.tryParse(currentGradeVal?.toString() ?? '') ??
              GradeMetadata.allGrades;

    if (_selectedGrade != currentGrade && !_isGradeLocked) {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'تأكيد تغيير الصف',
        content:
            'هل أنت متأكد من تغيير الصف الدراسي؟\n\nبمجرد التأكيد، لن تتمكن من تغيير الصف مرة أخرى لمدة 3 أيام لضمان استقرار سجلاتك الدراسية.',
        confirmLabel: 'تأكيد التغيير',
        confirmColor: AppColors.primary,
      );
      if (!confirmed) return;
    }

    final success = await authProvider.updateProfile(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      description: _descriptionController.text.trim(),
      grade: _selectedGrade,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح')));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.state.error ?? 'خطأ في التحديث')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.state.user;
    final rawAvatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final avatarUpdatedAt = user?.userMetadata?['avatar_updated_at'] as String?;
    final avatarUrl = rawAvatarUrl != null && avatarUpdatedAt != null
        ? '$rawAvatarUrl?v=${DateTime.parse(avatarUpdatedAt).millisecondsSinceEpoch}'
        : rawAvatarUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = AppTokens.isDesktop(context);
    final cardBg = isDark ? AppColors.cardDark : const Color(0xFFE5F3FF);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.profileEditScreen,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text(
            'تعديل ملفّي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (!_isInitialLoading)
              TextButton(
                onPressed: authProvider.state.isLoading ? null : _save,
                child: authProvider.state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'حفظ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.blue,
                        ),
                      ),
              ),
          ],
        ),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.paddingOf(context).top +
                        kToolbarHeight +
                        AppTokens.spacing16,
                    left: AppTokens.spacing16,
                    right: AppTokens.spacing16,
                    bottom: MediaQuery.paddingOf(context).bottom + 60,
                  ),
                  child: Column(
                    children: [
                      // Top Hero Card (#E5F3FF Container with Name Input & Grade Options)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(28.0),
                          border: Border.all(
                            color: AppColors.blue.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: isDesktop
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            // Desktop/Mobile Layout for Avatar & Name
                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildNameFormField(
                                      isDark,
                                      isDesktop,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  _buildAvatarCircle(
                                    context,
                                    isDark,
                                    avatarUrl,
                                    radius: 55,
                                  ),
                                ],
                              ),
                            ] else ...[
                              _buildAvatarCircle(
                                context,
                                isDark,
                                avatarUrl,
                                radius: 46,
                              ),
                              const SizedBox(height: 16),
                              _buildNameFormField(isDark, isDesktop),
                            ],
                            const SizedBox(height: 24),

                            // Grade Selection Section (ادخل الصف)
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildGradeOptionsSection(isDark),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 32.0,
                                        right: 16.0,
                                      ),
                                      child: _buildNoticeText(isDark),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildGradeOptionsSection(isDark),
                              const SizedBox(height: 16),
                              _buildNoticeText(isDark),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Form Container (Username & Bio Fields)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username Field
                            Text(
                              'اسم المستخدم',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.mutedDark
                                    : AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextFormField(
                                controller: _usernameController,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: InputBorder.none,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'يرجى إدخال اسم المستخدم';
                                  if (v.length < 3)
                                    return 'اسم المستخدم قصير جداً';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Bio / Description Field
                            Text(
                              'النبذة',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.mutedDark
                                    : AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authProvider.state.isLoading
                              ? null
                              : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: authProvider.state.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'حفظ التعديلات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNameFormField(bool isDark, bool isDesktop) {
    return TextFormField(
      controller: _nameController,
      textAlign: isDesktop ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        fontSize: isDesktop ? 26 : 20,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'الاسم الكامل',
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white30 : AppColors.textPrimary,
            width: 2,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white30 : AppColors.textPrimary,
            width: 2,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.blue, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال الاسم' : null,
    );
  }

  Widget _buildGradeOptionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ادخل الصف',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...GradeMetadata.grades.map((g) {
          final isSelected = _selectedGrade == g.id;
          return InkWell(
            onTap: _isGradeLocked
                ? null
                : () => setState(() => _selectedGrade = g.id),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 4.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    g.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.textPrimary)
                          : (isDark
                                ? AppColors.mutedDark
                                : AppColors.textMuted),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 18, color: Color(0xFF10B981)),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoticeText(bool isDark) {
    return Text(
      'يرجي العلم انه يمكنك التغيير كل ثلاثة ايام حيث ان الصف ثابت',
      style: TextStyle(
        fontSize: 12,
        height: 1.6,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.mutedDark : AppColors.textLight,
      ),
    );
  }

  Widget _buildAvatarCircle(
    BuildContext context,
    bool isDark,
    String? avatarUrl, {
    required double radius,
  }) {
    final avatarBg = isDark ? const Color(0xFF263852) : const Color(0xFF97CBFF);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
      child: ClipOval(
        child: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            ? Image.network(
                avatarUrl.trim(),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarLetters(radius),
              )
            : _buildAvatarLetters(radius),
      ),
    );
  }

  Widget _buildAvatarLetters(double radius) {
    final name = _nameController.text;
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
}
