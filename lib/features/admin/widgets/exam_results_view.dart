import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:intl/intl.dart' as intl;
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
  int _selectedGrade = 0; // 0 for All, 1, 2, 3 for Secondary
  String? _selectedExamId;
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _nonParticipants = [];
  bool _isDetailLoading = false;

  // Real-time subscription handles
  StreamSubscription<List<Map<String, dynamic>>>? _examsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _participantsSubscription;

  @override
  void initState() {
    super.initState();
    _initSubscriptions();
    _loadExams();
  }

  void _initSubscriptions() {
    // Listen for changes to exams list (when exams are published/unpublished)
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
    // Cancel previous subscription if exists
    _participantsSubscription?.cancel();

    // Subscribe to real-time updates for this exam's participants
    _participantsSubscription = _scoreRepository
        .streamExamParticipants(examId)
        .listen(
          (participants) async {
            if (!mounted) return;

            // Get all profiles in the grade for non-participants calculation
            final allInGrade = await _scoreRepository.getGradeProfiles(
              _selectedGrade,
            );

            // Filter non-participants: IDs in allInGrade that are NOT in participants
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

    // Fetch initial data
    final participants = await _scoreRepository.getExamParticipants(examId);
    final allInGrade = await _scoreRepository.getGradeProfiles(_selectedGrade);

    // Filter non-participants: IDs in allInGrade that are NOT in participants
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

    // Set up real-time subscription for ongoing updates
    _subscribeToParticipants(examId);
  }

  Future<void> _handleUnpublish(String examId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد إلغاء النشر'),
          content: Text(
            'هل أنت متأكد من رغبتك في إلغاء نشر امتحان "$title"؟ لن يتمكن الطلاب من رؤيته، ولكن سيتم الاحتفاظ بالنتائج السابقة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('إلغاء النشر'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildGradeFilter(),
        Expanded(
          child: _selectedExamId == null
              ? _buildExamsList()
              : _buildExamDetails(),
        ),
      ],
    );
  }

  Widget _buildGradeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing12,
        vertical: AppTokens.spacing8,
      ),
      color: AppColors.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'تصفية حسب الصف:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Horizontal scrollable filter chips for mobile
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(0, 'الكل'),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'أول ثانوي'),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'ثاني ثانوي'),
                const SizedBox(width: 8),
                _buildFilterChip(3, 'ثالث ثانوي'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int grade, String label) {
    final isSelected = _selectedGrade == grade;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGrade = grade;
          if (_selectedExamId != null) {
            _loadExamDetails(_selectedExamId!);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildExamsList() {
    if (_exams.isEmpty) {
      return const Center(child: Text('لا توجد امتحانات منشورة حالياً.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        final subjectId = exam['subject_id'] as String? ?? '';
        final category = CategoryMetadata.getById(subjectId);
        final subjectName = category?.name ?? exam['subject_id'] ?? 'غير محدد';
        final grade = exam['grade'] as int? ?? 0;
        final gradeText = grade == 0 ? 'جميع الصفوف' : '$gradeث';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEB8A00),
              child: Icon(Icons.quiz, color: Colors.white),
            ),
            title: Text(exam['title'] ?? 'بدون عنوان'),
            subtitle: Text('القسم: $subjectName - $gradeText'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _handleUnpublish(
                    exam['id'],
                    exam['title'] ?? 'هذا الامتحان',
                  ),
                  tooltip: 'إلغاء النشر',
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _loadExamDetails(exam['id']),
          ),
        );
      },
    );
  }

  Widget _buildExamDetails() {
    if (_isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedExamId = null),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _exams.firstWhere((e) => e['id'] == _selectedExamId)['title'],
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'المشاركون'),
                    Tab(text: 'لم يكتمل بعد'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildParticipantsList(),
                      _buildNonParticipantsList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsList() {
    if (_participants.isEmpty) {
      return const Center(
        child: Text('لم يقم أي طالب بأداء هذا الامتحان بعد.'),
      );
    }

    return ListView.builder(
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final p = _participants[index];
        final profile = p['profiles'] as Map<String, dynamic>?;
        final score = (p['score'] as num).toDouble();
        // Convert DB grade (10, 11, 12) to UI grade (1, 2, 3)
        final dbGrade = profile?['grade'] as int? ?? 0;
        final uiGrade = dbGrade > 9 ? dbGrade - 9 : dbGrade;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: score >= 50 ? Colors.green : Colors.red,
            child: Text(
              '${score.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          title: Text(
            profile?['full_name'] ?? profile?['username'] ?? 'مستخدم مجهول',
          ),
          subtitle: Text('الصف: $uiGradeث'),
          trailing: Text(
            intl.DateFormat(
              'MM/dd HH:mm',
            ).format(DateTime.parse(p['created_at'])),
          ),
          onTap: () => _showWrongAnswers(p['wrong_answers']),
        );
      },
    );
  }

  Widget _buildNonParticipantsList() {
    if (_nonParticipants.isEmpty) {
      return const Center(
        child: Text('جميع الطلاب في هذا الصف أتموا الامتحان!'),
      );
    }

    return ListView.builder(
      itemCount: _nonParticipants.length,
      itemBuilder: (context, index) {
        final profile = _nonParticipants[index];
        // Convert DB grade (10, 11, 12) to UI grade (1, 2, 3)
        final dbGrade = profile['grade'] as int? ?? 0;
        final uiGrade = dbGrade > 9 ? dbGrade - 9 : dbGrade;
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(
            profile['full_name'] ?? profile['username'] ?? 'مستخدم مجهول',
          ),
          subtitle: Text('الصف: $uiGradeث - @${profile['username']}'),
        );
      },
    );
  }

  void _showWrongAnswers(dynamic wrongAnswers) {
    List<String> questions = [];
    if (wrongAnswers is List) {
      questions = wrongAnswers.map((q) => q.toString()).toList();
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأسئلة التي أخطأ فيها الطالب:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (questions.isEmpty)
                const Text('أجاب الطالب على جميع الأسئلة بشكل صحيح! 🎉')
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      title: Text('سؤال ID: ${questions[index]}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
