import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/auth/widgets/glass_container.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_view.dart';
import 'package:arabilogia/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class TeacherPanelScreen extends StatefulWidget {
  const TeacherPanelScreen({super.key});

  @override
  State<TeacherPanelScreen> createState() => _TeacherPanelScreenState();
}

class _TeacherPanelScreenState extends State<TeacherPanelScreen> {
  String _selectedCategoryId = CategoryMetadata.categories.first.id;
  int _selectedGrade = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTeacherRole();
    });
  }

  void _checkTeacherRole() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isTeacher) {
      if (mounted) {
        context.go(AppRoutes.dashboard);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('غير مصرح لك بالوصول لهذه الصفحة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(
            auth.isAdmin ? 'لوحة الإدارة' : 'لوحة المعلم',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.go(AppRoutes.login),
            ),
          ],
        ),
        body: const ExamResultsView(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.examEditor),
          backgroundColor: const Color(0xFFEB8A00),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة امتحان'),
        ),
      ),
    );
  }

  Widget _buildAddExamTab(bool isDark) {
    final isMobile = AppTokens.isMobile(context);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDark
                ? AppTokens.mobileDarkBackground
                : AppTokens.mobileBackground,
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppTokens.spacing16,
              right: AppTokens.spacing16,
              top: AppTokens.spacing16,
              bottom:
                  AppTokens.spacing16 + MediaQuery.of(context).padding.bottom,
            ),
            child: GlassContainer(
              isMobile: isMobile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إضافة امتحان جديد',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeLg,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEB8A00),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'اختر القسم',
                      filled: true,
                      fillColor: AppColors.glassBackgroundColor(
                        context,
                      ).withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                    ),
                    items: CategoryMetadata.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(cat.icon, color: cat.color, size: 20),
                            const SizedBox(width: 12),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedCategoryId = val);
                    },
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  DropdownButtonFormField<int>(
                    value: _selectedGrade,
                    decoration: InputDecoration(
                      labelText: 'الصف المستهدف',
                      filled: true,
                      fillColor: AppColors.glassBackgroundColor(
                        context,
                      ).withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('الأول الثانوي')),
                      DropdownMenuItem(value: 2, child: Text('الثاني')),
                      DropdownMenuItem(value: 3, child: Text('الثالث')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGrade = val);
                    },
                  ),
                  const SizedBox(height: AppTokens.spacing24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.examEditor);
                    },
                    icon: const Icon(Icons.edit, size: 28),
                    label: const Text(
                      'إضافة أسئلة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB8A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spacing24,
                        horizontal: AppTokens.spacing32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  Text(
                    'سيتم فتح المحرر المرئي لإضافة وتحرير الأسئلة',
                    style: TextStyle(
                      color: AppColors.authHeaderColor(context),
                      fontSize: AppTokens.fontSizeSm,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
