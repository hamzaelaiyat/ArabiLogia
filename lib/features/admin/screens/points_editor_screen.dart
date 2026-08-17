import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';
import 'package:arabilogia/features/admin/providers/points_provider.dart';
import 'package:arabilogia/features/admin/widgets/student_point_card.dart';
import 'package:arabilogia/features/admin/widgets/reset_confirm_dialog.dart';
import 'package:arabilogia/features/auth/providers/auth_provider.dart';

class PointsEditorScreen extends StatefulWidget {
  const PointsEditorScreen({super.key});

  @override
  State<PointsEditorScreen> createState() => _PointsEditorScreenState();
}

class _PointsEditorScreenState extends State<PointsEditorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTeacherRole();
      context.read<PointsProvider>().loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkTeacherRole() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isTeacher) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('غير مصرح لك بالوصول لهذه الصفحة')),
        );
      }
    }
  }

  Future<void> _handleIncrement(String userId, int amount) async {
    if (_processingIds.contains(userId)) return;
    setState(() => _processingIds.add(userId));
    try {
      final result = await context.read<PointsProvider>().increment(userId, amount);
      if (mounted) {
        _showResultSnack(
          result != null,
          result != null ? 'تمت إضافة $amount نقطة' : 'فشلت العملية',
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(userId));
    }
  }

  Future<void> _handleDecrement(String userId, int amount) async {
    if (_processingIds.contains(userId)) return;
    setState(() => _processingIds.add(userId));
    try {
      final result = await context.read<PointsProvider>().decrement(userId, amount);
      if (mounted) {
        _showResultSnack(
          result != null,
          result != null ? 'تم خصم $amount نقطة' : 'فشلت العملية',
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(userId));
    }
  }

  Future<void> _handleReset(Map<String, dynamic> student) async {
    final userId = student['user_id'] as String? ?? student['id'] as String?;
    if (userId == null || _processingIds.contains(userId)) return;

    final name = student['full_name'] as String? ?? 'هذا الطالب';
    final balance = _getBalance(student);
    final provider = context.read<PointsProvider>();
    final confirmed = await showResetPointsConfirmDialog(context, name, balance);
    if (!confirmed) return;
    setState(() => _processingIds.add(userId));
    try {
      final result = await provider.reset(userId);
      if (mounted) {
        _showResultSnack(
          result != null,
          result != null ? 'تم إعادة تعيين النقاط إلى صفر' : 'فشلت العملية',
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(userId));
    }
  }

  void _showResultSnack(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _getBalance(Map<String, dynamic> student) {
    final v = student['total_balance'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  String _getUserId(Map<String, dynamic> student) {
    return student['user_id'] as String? ?? student['id'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PointsProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة النقاط',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => provider.loadStudents(force: true),
            ),
          ],
        ),
        body: Column(
          children: [
            _SearchAndFilter(
              searchController: _searchController,
              selectedGrade: provider.selectedGrade,
              onSearchChanged: provider.setSearchQuery,
              onGradeChanged: (g) {
                provider.setGrade(g);
                provider.loadStudents(grade: g, force: true);
              },
            ),
            Expanded(
              child: _buildBody(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PointsProvider provider) {
    if (provider.isLoading && provider.students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('حدث خطأ: ${provider.error}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadStudents(force: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final students = provider.students;

    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.mutedColor(context),
            ),
            const SizedBox(height: 12),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث'
                  : 'لا يوجد طلاب مسجلين',
              style: TextStyle(color: AppColors.mutedColor(context)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadStudents(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final userId = _getUserId(student);
          return StudentPointCard(
            student: student,
            isProcessing: _processingIds.contains(userId),
            onIncrement: (amount) => _handleIncrement(userId, amount),
            onDecrement: (amount) => _handleDecrement(userId, amount),
            onReset: () => _handleReset(student),
          );
        },
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final TextEditingController searchController;
  final int? selectedGrade;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onGradeChanged;

  const _SearchAndFilter({
    required this.searchController,
    required this.selectedGrade,
    required this.onSearchChanged,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ابحث عن طالب...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _GradeChip(
                  grade: 0,
                  label: 'الكل',
                  isSelected: selectedGrade == null || selectedGrade == 0,
                  onTap: () => onGradeChanged(null),
                ),
                ...GradeMetadata.grades.expand((g) => [
                  const SizedBox(width: 8),
                  _GradeChip(
                    grade: g.id,
                    label: g.name,
                    isSelected: selectedGrade == g.id,
                    onTap: () => onGradeChanged(g.id),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final int grade;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradeChip({
    required this.grade,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
