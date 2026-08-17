import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_view.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class TeacherPanelScreen extends StatefulWidget {
  const TeacherPanelScreen({super.key});

  @override
  State<TeacherPanelScreen> createState() => _TeacherPanelScreenState();
}

class _TeacherPanelScreenState extends State<TeacherPanelScreen> {
  final GlobalKey<State<ExamResultsView>> _examResultsKey = GlobalKey();

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
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.teacherPanelScreen,
        extendBody: true,
        appBar: AppBar(
          title: Text(
            auth.isAdmin ? 'لوحة الإدارة' : 'لوحة المعلم',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () {
                (_examResultsKey.currentState as dynamic)?.refresh();
              },
            ),
          ],
        ),
        body: ExamResultsView(key: _examResultsKey),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Settings button (gear icon)
            FloatingActionButton(
              heroTag: 'settings',
              onPressed: () => context.push(AppRoutes.teacherSettings),
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: AppColors.primary,
              mini: true,
              child: const Icon(Icons.settings),
            ),
            const SizedBox(height: 12),
            // Manage Points button
            FloatingActionButton.extended(
              heroTag: 'managePoints',
              onPressed: () => context.push(AppRoutes.pointsEditor),
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('إدارة النقاط'),
            ),
            const SizedBox(height: 12),
            // Add Lecture button
            FloatingActionButton.extended(
              heroTag: 'addLecture',
              onPressed: () => context.push(AppRoutes.lectureEditor),
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('إضافة محاضرة'),
            ),
          ],
        ),
      ),
    );
  }
}
