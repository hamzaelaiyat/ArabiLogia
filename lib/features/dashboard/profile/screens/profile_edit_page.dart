import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/section_title.dart';
import 'package:arabilogia/core/widgets/confirmation_dialog.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:arabilogia/features/dashboard/profile/widgets/grade_selector.dart';
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
    _nameController = TextEditingController(text: user?.userMetadata?['full_name']);
    _usernameController = TextEditingController(text: user?.userMetadata?['username']);
    _descriptionController = TextEditingController(text: user?.userMetadata?['description']);
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
    if (gradeVal is int) {
      _selectedGrade = gradeVal;
    } else if (gradeVal != null) {
      _selectedGrade = int.tryParse(gradeVal.toString());
    } else {
      _selectedGrade = 0;
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
          _gradeUpdatedAt = rawDate is String ? DateTime.tryParse(rawDate) : null;
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

  String _getLockMessage() {
    if (_gradeUpdatedAt == null) return '';
    final remaining =
        const Duration(days: 3) - DateTime.now().difference(_gradeUpdatedAt!);
    if (remaining.inDays > 0)
      return 'يمكنك التغيير بعد ${remaining.inDays} يوم';
    if (remaining.inHours > 0)
      return 'يمكنك التغيير بعد ${remaining.inHours} ساعة';
    return 'يمكنك التغيير بعد قليل';
  }

  Future<void> _save() async {
    final authProvider = context.read<AuthProvider>();

    final user = authProvider.state.user;
    final currentGradeVal = user?.userMetadata?['grade'];
    final int currentGrade = currentGradeVal is int
        ? currentGradeVal
        : int.tryParse(currentGradeVal?.toString() ?? '') ?? 0;

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.profileEditScreen,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text(
            'تعديل الملف الشخصي',
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
          ],
        ),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.paddingOf(context).top +
                        kToolbarHeight +
                        AppTokens.spacing16,
                    left: AppTokens.spacing16,
                    right: AppTokens.spacing16,
                    bottom: MediaQuery.paddingOf(context).bottom + 100,
                  ),
                  children: [
                    const SectionTitle(title: 'المعلومات الأساسية'),
                    const SizedBox(height: AppTokens.spacing16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'يرجى إدخال الاسم' : null,
                    ),
                    const SizedBox(height: AppTokens.spacing16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.alternate_email),
                        helperText: 'يجب أن يكون فريداً وغير مستخدم',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'يرجى إدخال اسم المستخدم';
                        if (v.length < 3) return 'اسم المستخدم قصير جداً';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTokens.spacing16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'نبذة عني',
                        prefixIcon: Icon(Icons.description_outlined),
                        helperText: 'اكتب نبذة مختصرة عن نفسك',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: AppTokens.spacing32),
                    const SectionTitle(title: 'الدراسة'),
                    const SizedBox(height: AppTokens.spacing16),
                    GradeSelector(
                      selectedGrade: _selectedGrade,
                      isGradeLocked: _isGradeLocked,
                      onSelect: (grade) =>
                          setState(() => _selectedGrade = grade),
                    ),
                    const GradeChangeNotice(),
                    if (_isGradeLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_clock_outlined,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getLockMessage(),
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
