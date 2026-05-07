import 'package:flutter/material.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
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
  final ScoreRepository _scoreRepository = ScoreRepository();
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
    _loadExams();
  }

  void _initSubscriptions() {
    _examsSubscription = _scoreRepository.streamExamsManaged().listen(
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

    _participantsSubscription = _scoreRepository
        .streamExamParticipants(examId)
        .listen(
          (participants) async {
            if (!mounted) return;

            final allInGrade = await _scoreRepository.getGradeProfiles(
              _selectedGrade,
            );

            final participantIds = participants
                .map((p) => p['user_id'])
                .toSet();
            final nonParticipants = allInGrade
                .where((profile) => !participantIds.contains(profile['id']))
                .toList();

            setState(() {
              _participants = participants;
              _nonParticipants = nonParticipants;
              _isDetailLoading = false;
            });
          },
          onError: (error) {
            debugPrint('Error in participants stream subscription: $error');
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

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final exams = await _scoreRepository.getExamsManaged();
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

    final participants = await _scoreRepository.getExamParticipants(examId);
    final allInGrade = await _scoreRepository.getGradeProfiles(_selectedGrade);

    final participantIds = participants.map((p) => p['user_id']).toSet();
    final nonParticipants = allInGrade
        .where((profile) => !participantIds.contains(profile['id']))
        .toList();

    if (mounted) {
      setState(() {
        _participants = participants;
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
            const SnackBar(content: Text('تم إلغاء نشر الامتحان بنجاح')),
          );
          _loadExams();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إلغاء النشر: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
          onUnpublish: () => _handleUnpublish(
            exam['id'],
            exam['title'] ?? 'هذا الامتحان',
          ),
        );
      },
    );
  }
}