import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/providers/auth_provider.dart';
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
  int? _selectedGrade;
  DateTime? _gradeUpdatedAt;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.state.user;
    
    _nameController = TextEditingController(text: user?.userMetadata?['full_name']);
    _usernameController = TextEditingController(text: user?.userMetadata?['username']);
    final gradeVal = user?.userMetadata?['grade'];
    if (gradeVal is int) {
      _selectedGrade = gradeVal;
    } else if (gradeVal != null) {
      _selectedGrade = int.tryParse(gradeVal.toString());
    } else {
      _selectedGrade = 0;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('grade_updated_at')
          .eq('id', user!.id)
          .single();
      
      if (mounted) {
        setState(() {
          _gradeUpdatedAt = DateTime.parse(response['grade_updated_at']);
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool get _isGradeLocked {
    if (_gradeUpdatedAt == null) return false;
    return DateTime.now().difference(_gradeUpdatedAt!).inDays < 3;
  }

  String _getLockMessage() {
    if (_gradeUpdatedAt == null) return '';
    final remaining = const Duration(days: 3) - DateTime.now().difference(_gradeUpdatedAt!);
    if (remaining.inDays > 0) return 'يمكنك التغيير بعد ${remaining.inDays} يوم';
    if (remaining.inHours > 0) return 'يمكنك التغيير بعد ${remaining.inHours} ساعة';
    return 'يمكنك التغيير بعد قليل';
  }

  Future<void> _save() async {
    final authProvider = context.read<AuthProvider>();
    
    // Check if grade changed
    final user = authProvider.state.user;
    final currentGradeVal = user?.userMetadata?['grade'];
    final int currentGrade = currentGradeVal is int ? currentGradeVal : int.tryParse(currentGradeVal?.toString() ?? '') ?? 0;
    
    if (_selectedGrade != currentGrade && !_isGradeLocked) {
      final confirmed = await _showGradeChangeConfirmation();
      if (!confirmed) return;
    }

    final success = await authProvider.updateProfile(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      grade: _selectedGrade,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.state.error ?? 'خطأ في التحديث')),
      );
    }
  }

  Future<bool> _showGradeChangeConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد تغيير الصف'),
          content: const Text(
            'هل أنت متأكد من تغيير الصف الدراسي؟\n\nبمجرد التأكيد، لن تتمكن من تغيير الصف مرة أخرى لمدة 3 أيام لضمان استقرار سجلاتك الدراسية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد التغيير'),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + kToolbarHeight + AppTokens.spacing16,
                    left: AppTokens.spacing16,
                    right: AppTokens.spacing16,
                    bottom: AppTokens.spacing16,
                  ),
                  children: [
                    _buildSectionHeader('المعلومات الأساسية'),
                    const SizedBox(height: AppTokens.spacing16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال الاسم' : null,
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
                        if (v == null || v.isEmpty) return 'يرجى إدخال اسم المستخدم';
                        if (v.length < 3) return 'اسم المستخدم قصير جداً';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTokens.spacing32),
                    _buildSectionHeader('الدراسة'),
                    const SizedBox(height: AppTokens.spacing16),
                    _buildGradeSelector(),
                    _buildGradeNotice(),
                    if (_isGradeLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock_outlined, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              _getLockMessage(),
                              style: const TextStyle(color: AppColors.warning, fontSize: 12),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGradeSelector() {
    final grades = [
      {'value': 10, 'label': 'الأولى باكالوريا'},
      {'value': 11, 'label': 'الثانية ثانوي'},
      {'value': 12, 'label': 'الثالثة ثانوي'},
    ];

    return Column(
      children: grades.map((g) {
        final isSelected = _selectedGrade == g['value'];
        final isLocked = _isGradeLocked && !isSelected;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface(context),
            borderRadius: AppTokens.radiusMdAll,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: ListTile(
            title: Text(g['label'] as String),
            trailing: isSelected 
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : isLocked ? const Icon(Icons.lock_outline, size: 20) : null,
            onTap: isLocked ? null : () {
              setState(() => _selectedGrade = g['value'] as int);
            },
            enabled: !isLocked,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradeNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: AppTokens.radiusMdAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: يمكنك تغيير الصف الدراسي مرة واحدة كل 3 أيام فقط.',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
