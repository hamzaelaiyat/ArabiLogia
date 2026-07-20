import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/glass_app_bar.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/exam_repository.dart';
import 'package:arabilogia/features/dashboard/exams/repositories/score_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/models/lecture.dart';
import 'package:arabilogia/features/dashboard/lectures/repositories/lecture_repository.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/progress_bar_card.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/text_block_widget.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/youtube_block_widget.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/quiz_block_widget.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/standard_exam_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LectureDetailScreen extends StatefulWidget {
  final String lectureId;

  const LectureDetailScreen({super.key, required this.lectureId});

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  final LectureRepository _repository = LectureRepository();
  Lecture? _lecture;
  List<Exam> _exams = [];
  bool _isLoading = true;
  Set<String> _completedBlockIds = {};
  Map<String, Map<String, dynamic>> _examScores = {};

  @override
  void initState() {
    super.initState();
    _loadLectureDetails();
  }

  Future<void> _loadLectureDetails() async {
    final lecture = await _repository.getLectureById(widget.lectureId);
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList('lecture_progress_${widget.lectureId}') ?? [];
    
    final scores = await ScoreRepository().getLocalScores();

    if (lecture != null) {
      final loadedExams = <Exam>[];
      for (var id in lecture.examIds) {
        final exam = await ExamRepository().loadExamById(lecture.courseId, id);
        if (exam != null) {
          loadedExams.add(exam);
        }
      }

      if (mounted) {
        setState(() {
          _lecture = lecture;
          _exams = loadedExams;
          _completedBlockIds = Set.from(completedList);
          _examScores = scores.map((key, val) => MapEntry(key, Map<String, dynamic>.from(val)));
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadScores() async {
    final scores = await ScoreRepository().getLocalScores();
    if (mounted) {
      setState(() {
        _examScores = scores.map((key, val) => MapEntry(key, Map<String, dynamic>.from(val)));
      });
    }
  }

  Future<void> _toggleBlockCompletion(String blockId) async {
    final isCompleted = _completedBlockIds.contains(blockId);
    setState(() {
      if (isCompleted) {
        _completedBlockIds.remove(blockId);
      } else {
        _completedBlockIds.add(blockId);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('lecture_progress_${widget.lectureId}', _completedBlockIds.toList());
  }

  double get _progressPercentage {
    if (_lecture == null) return 0.0;
    final total = _lecture!.contentBlocks.length + _exams.length;
    if (total == 0) return 0.0;
    
    int completedCount = 0;
    for (var block in _lecture!.contentBlocks) {
      if (_completedBlockIds.contains(block.id)) {
        completedCount++;
      }
    }
    for (var exam in _exams) {
      if (_examScores.containsKey(exam.id)) {
        completedCount++;
      }
    }
    return completedCount / total;
  }

  CategoryMetadata? get _category {
    if (_lecture == null) return null;
    return CategoryMetadata.getById(_lecture!.courseId);
  }

  Widget _buildContentBlock(LectureContentBlock block, Color categoryColor) {
    final isCompleted = _completedBlockIds.contains(block.id);

    switch (block.type) {
      case BlockType.text:
        return TextBlockWidget(
          block: block,
          isCompleted: isCompleted,
          onToggleCompletion: () => _toggleBlockCompletion(block.id),
        );
      case BlockType.youtube:
        return YoutubeBlockWidget(
          block: block,
          isCompleted: isCompleted,
          onToggleCompletion: () => _toggleBlockCompletion(block.id),
        );
      case BlockType.exam:
      case BlockType.quiz:
        return QuizBlockWidget(
          block: block,
          isCompleted: isCompleted,
          examScores: _examScores,
          lectureCourseId: _lecture!.courseId,
          lectureId: _lecture!.id,
          categoryName: _category?.name ?? '',
          onToggleCompletion: () => _toggleBlockCompletion(block.id),
          onScoreRefresh: _loadScores,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_lecture == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('عذراً، لم يتم العثور على تفاصيل المحاضرة'),
        ),
      );
    }

    final category = _category;
    final categoryColor = category?.color ?? AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: TestKeys.lectureDetailScreen,
        appBar: GlassAppBar(
          title: Text(
            _lecture!.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressBarCard(progress: _progressPercentage, categoryColor: categoryColor),
              const SizedBox(height: AppTokens.spacing16),
              ..._lecture!.contentBlocks.map((block) => _buildContentBlock(block, categoryColor)),
              
              if (_exams.isNotEmpty) ...[
                const SizedBox(height: AppTokens.spacing24),
                const Divider(),
                const SizedBox(height: AppTokens.spacing16),
                Text(
                  'الامتحانات الختامية للمحاضرة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: AppTokens.spacing12),
                ..._exams.map((exam) => StandardExamWidget(
                  exam: exam,
                  examScores: _examScores,
                  lectureCourseId: _lecture!.courseId,
                  categoryName: _category?.name ?? '',
                  onScoreRefresh: _loadScores,
                )),
              ],
              const SizedBox(height: AppTokens.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
