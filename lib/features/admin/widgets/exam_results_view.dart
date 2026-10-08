import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_filter.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_card.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_dialogs.dart';
import 'package:arabilogia/core/models/grade_metadata.dart';

class ExamResultsView extends StatefulWidget {
  const ExamResultsView({super.key});

  @override
  State<ExamResultsView> createState() => _ExamResultsViewState();
}

class _ExamResultsViewState extends State<ExamResultsView> {
  final LectureRepository _lectureRepository = LectureRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _lectures = [];
  int _selectedGrade = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _lecturesSubscription;

  @override
  void initState() {
    super.initState();
    _initSubscriptions();
    refresh();
  }

  void _initSubscriptions() {
    _lecturesSubscription = _lectureRepository
        .streamLecturesManagedRealtime()
        .listen(
          (lectures) {
            if (mounted) {
              setState(() {
                _lectures = lectures;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            debugPrint('Error in lectures stream subscription: $error');
          },
        );
  }

  @override
  void dispose() {
    _lecturesSubscription?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() => _isLoading = true);
    final lectures = await _lectureRepository.getLecturesManaged();
    if (mounted) {
      setState(() {
        _lectures = lectures;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDelete(String lectureId, String title) async {
    final confirmed = await showLectureDeleteConfirmDialog(context, title);
    if (!confirmed) return;

    try {
      await _lectureRepository.deleteLecture(lectureId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف المحاضرة بنجاح')));
        refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleTogglePublish(
    String lectureId,
    String title,
    bool currentStatus,
  ) async {
    final newStatus = !currentStatus;
    final confirmed = newStatus
        ? await showPublishConfirmDialog(context, title)
        : await showUnpublishConfirmDialog(context, title);

    if (!confirmed) return;

    try {
      await _lectureRepository.togglePublishStatus(lectureId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'تم نشر المحاضرة بنجاح'
                  : 'تم تحويل المحاضرة إلى مسودة',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
        refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل العملية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> lectureMap) async {
    try {
      final lecture = Lecture.fromJson(lectureMap);
      await context.push(AppRoutes.lectureEditor, extra: lecture);
      refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل فتح محرر المحاضرات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleGradeChanged(int grade) {
    setState(() {
      _selectedGrade = grade;
    });
  }

  Future<void> _handleViewResults(Map<String, dynamic> lectureMap) async {
    final lecture = Lecture.fromJson(lectureMap);
    await context.push(AppRoutes.lectureResults, extra: lecture);
  }

  List<Map<String, dynamic>> get _filteredLectures {
    if (_selectedGrade == 0) return _lectures;
    return _lectures
        .where(
          (l) =>
              (l['grade'] as int? ?? GradeMetadata.allGrades) == _selectedGrade,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        ExamResultsFilter(
          selectedGrade: _selectedGrade,
          onGradeChanged: _handleGradeChanged,
        ),
        Expanded(child: _buildLecturesList()),
      ],
    );
  }

  Widget _buildLecturesList() {
    final list = _filteredLectures;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'لا توجد محاضرات حالياً في هذا الصف.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push(AppRoutes.lectureEditor);
                refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة محاضرة جديدة'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final lecture = list[index];
        final isPublished = lecture['is_published'] == true;
        final title = lecture['title'] as String? ?? 'بدون عنوان';

        return ExamResultsCard(
          exam: lecture,
          onTap: () => _handleViewResults(lecture),
          onPublish: isPublished
              ? null
              : () => _handleTogglePublish(lecture['id'], title, isPublished),
          onEdit: () => _handleEdit(lecture),
          onUnpublish: isPublished
              ? () => _handleTogglePublish(lecture['id'], title, isPublished)
              : null,
          onViewResults: () => _handleViewResults(lecture),
          onDelete: () => _handleDelete(lecture['id'], title),
        );
      },
    );
  }
}
