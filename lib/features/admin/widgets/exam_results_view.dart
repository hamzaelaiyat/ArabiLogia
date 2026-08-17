import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_filter.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_card.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_dialogs.dart';
import 'package:arabilogia/features/admin/widgets/exam_results_detail_view.dart';
import 'dart:async';

class ExamResultsView extends StatefulWidget {
  const ExamResultsView({super.key});

  @override
  State<ExamResultsView> createState() => _ExamResultsViewState();
}

class _ExamResultsViewState extends State<ExamResultsView> {
  final ExamRepository _examRepository = ExamRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];
  int _selectedGrade = 0;
  String? _selectedExamId;
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _nonParticipants = [];
  bool _isDetailLoading = false;

  StreamSubscription<List<Map<String, dynamic>>>? _examsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _participantsSubscription;

  @override
  void initState() {
    super.initState();
    _initSubscriptions();
    refresh();
  }

  void _initSubscriptions() {
    _examsSubscription = _examRepository.streamExamsManagedRealtime().listen(
      (exams) {
        if (mounted) {
          setState(() => _exams = exams);
        }
      },
      onError: (error) {
        debugPrint('Error in exams stream subscription: $error');
      },
    );
  }

  void _subscribeToParticipants(String examId) {
    _participantsSubscription?.cancel();

    _participantsSubscription = _examRepository
        .streamExamParticipantsRealtime(examId)
        .listen(
          (participants) async {
            if (!mounted) return;

            final allInGrade = await _examRepository.getGradeProfiles(
              _selectedGrade,
            );

            final filteredParticipants = _filterParticipantsByGrade(participants);
            final participantIds = filteredParticipants
                .map((p) => p['user_id'])
                .toSet();
            final nonParticipants = allInGrade
                .where((profile) => !participantIds.contains(profile['id']))
                .toList();

            debugPrint(
              '_subscribeToParticipants: ${filteredParticipants.length} participants '
              '(filtered from ${participants.length}), '
              '${nonParticipants.length} non-participants',
            );

            setState(() {
              _participants = filteredParticipants;
              _nonParticipants = nonParticipants;
              _isDetailLoading = false;
            });
          },
          onError: (error) {
            debugPrint('_subscribeToParticipants error for exam $examId: $error');
            if (mounted) {
              setState(() => _isDetailLoading = false);
            }
          },
        );
  }

  @override
  void dispose() {
    _examsSubscription?.cancel();
    _participantsSubscription?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() => _isLoading = true);
    final exams = await _examRepository.getExamsManaged();
    if (mounted) {
      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExamDetails(String examId) async {
    setState(() {
      _selectedExamId = examId;
      _isDetailLoading = true;
    });

    final participants = await _examRepository.getExamParticipants(examId);
    final allInGrade = await _examRepository.getGradeProfiles(_selectedGrade);

    final filteredParticipants = _filterParticipantsByGrade(participants);
    final participantIds = filteredParticipants.map((p) => p['user_id']).toSet();
    final nonParticipants = allInGrade
        .where((profile) => !participantIds.contains(profile['id']))
        .toList();

    debugPrint(
      '_loadExamDetails: exam=$examId, participants=${filteredParticipants.length} '
      '(filtered from ${participants.length}), profilesInGrade=${allInGrade.length}',
    );

    if (mounted) {
      setState(() {
        _participants = filteredParticipants;
        _nonParticipants = nonParticipants;
        _isDetailLoading = false;
      });
    }

    _subscribeToParticipants(examId);
  }

  Future<void> _handleUnpublish(String examId, String title) async {
    final confirmed = await showUnpublishConfirmDialog(context, title);

    if (confirmed) {
      try {
        await _examRepository.unpublishExam(examId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الامتحان بنجاح')),
          );
          refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePublish(String examId, String title) async {
    final confirmed = await showPublishConfirmDialog(context, title);
    if (!confirmed) return;

    try {
      await _examRepository.publishDraft(examId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر الامتحان بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل النشر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(String examId, String subjectId) async {
    try {
      final exam = await _examRepository.loadExamById(subjectId, examId);
      if (!mounted) return;

      if (exam == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على الامتحان'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await context.push(AppRoutes.examEditor, extra: exam);
      refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل الامتحان: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filterParticipantsByGrade(
    List<Map<String, dynamic>> participants,
  ) {
    if (_selectedGrade == 0) return participants;
    final dbGrade = _selectedGrade;
    return participants.where((p) {
      final profile = p['profile'] as Map<String, dynamic>?;
      return profile?['grade'] == dbGrade;
    }).toList();
  }

  void _handleGradeChanged(int grade) {
    setState(() {
      _selectedGrade = grade;
      if (_selectedExamId != null) {
        _loadExamDetails(_selectedExamId!);
      }
    });
  }

  String get _currentExamTitle {
    if (_selectedExamId == null) return '';
    final exam = _exams.firstWhere(
      (e) => e['id'] == _selectedExamId,
      orElse: () => {'title': ''},
    );
    return exam['title'] as String? ?? '';
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
        Expanded(
          child: _selectedExamId == null
              ? _buildExamsList()
              : ExamResultsDetailView(
                  examTitle: _currentExamTitle,
                  isLoading: _isDetailLoading,
                  participants: _participants,
                  nonParticipants: _nonParticipants,
                  onBack: () => setState(() => _selectedExamId = null),
                  onShowWrongAnswers: (wrongAnswers) =>
                      showWrongAnswersSheet(context, wrongAnswers),
                ),
        ),
      ],
    );
  }

  Widget _buildExamsList() {
    if (_exams.isEmpty) {
      return const Center(child: Text('لا توجد امتحانات منشورة حالياً.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return ExamResultsCard(
          exam: exam,
          onTap: () => _loadExamDetails(exam['id']),
          onPublish: () => _handlePublish(
            exam['id'],
            exam['title'] ?? 'هذا الامتحان',
          ),
          onEdit: () => _handleEdit(
            exam['id'],
            exam['subject_id'] as String? ?? 'nahw',
          ),
          onUnpublish: () => _handleUnpublish(
            exam['id'],
            exam['title'] ?? 'هذا الامتحان',
          ),
        );
      },
    );
  }
}