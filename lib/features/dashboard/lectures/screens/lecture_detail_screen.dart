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
import 'package:arabilogia/features/dashboard/lectures/widgets/lecture_hero_card.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/lecture_toc.dart';
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
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _blockKeys = {};
  final GlobalKey _examsSectionKey = GlobalKey();
  int _activeTocIndex = 0;
  Lecture? _lecture;
  List<Exam> _exams = [];
  bool _isLoading = true;
  Set<String> _completedBlockIds = {};
  Map<String, Map<String, dynamic>> _examScores = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveToc);
    _loadLectureDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLectureDetails() async {
    final lecture = await _repository.getLectureById(widget.lectureId);
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList('lecture_progress_${widget.lectureId}') ?? [];

    final scores = await ScoreRepository().getLocalScores();

    if (lecture != null) {
      final loadedExams = (await Future.wait(
        lecture.examIds.map(
          (id) => ExamRepository().loadExamById(lecture.courseId, id),
        ),
      ))
          .whereType<Exam>()
          .toList();

      for (final block in lecture.contentBlocks) {
        _blockKeys.putIfAbsent(block.id, () => GlobalKey());
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

  Future<void> _persistCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('lecture_progress_${widget.lectureId}', _completedBlockIds.toList());
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
    await _persistCompleted();
  }

  Future<void> _markAllRead() async {
    setState(() {
      _completedBlockIds.addAll(_lecture!.contentBlocks.map((b) => b.id));
    });
    await _persistCompleted();
  }

  Future<void> _resetProgress() async {
    setState(() => _completedBlockIds.clear());
    await _persistCompleted();
  }

  CategoryMetadata? get _category {
    if (_lecture == null) return null;
    return CategoryMetadata.getById(_lecture!.courseId);
  }

  List<GlobalKey> get _orderedKeys {
    final keys = _lecture!.contentBlocks
        .map((b) => _blockKeys.putIfAbsent(b.id, () => GlobalKey()))
        .toList();
    if (_exams.isNotEmpty) keys.add(_examsSectionKey);
    return keys;
  }

  void _updateActiveToc() {
    if (_lecture == null) return;
    final keys = _orderedKeys;
    int active = 0;
    for (int i = 0; i < keys.length; i++) {
      final ctx = keys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= 200) active = i;
    }
    if (active != _activeTocIndex) {
      setState(() => _activeTocIndex = active);
    }
  }

  void _jumpToEntry(int index) {
    final keys = _orderedKeys;
    if (index < 0 || index >= keys.length) return;
    final ctx = keys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: AppTokens.durationMd,
        curve: AppTokens.curveDefault,
        alignment: 0.05,
      );
    }
  }

  String _textBlockLabel(LectureContentBlock block, int index) {
    final firstLine = block.content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    final cleaned = firstLine.replaceAll(RegExp(r'[#*>`]'), '').trim();
    if (cleaned.isEmpty) return 'فقرة $index';
    return cleaned.length > 40 ? '${cleaned.substring(0, 40)}…' : cleaned;
  }

  List<LectureTocEntry> get _tocEntries {
    final entries = <LectureTocEntry>[];
    int textIndex = 0;
    int videoIndex = 0;
    int quizIndex = 0;
    for (final block in _lecture!.contentBlocks) {
      switch (block.type) {
        case BlockType.text:
          textIndex++;
          entries.add(LectureTocEntry(
            label: _textBlockLabel(block, textIndex),
            icon: Icons.notes,
          ));
        case BlockType.youtube:
          videoIndex++;
          entries.add(LectureTocEntry(
            label: block.metadata?['title']?.toString() ?? 'فيديو الشرح $videoIndex',
            icon: Icons.play_circle_outline,
          ));
        case BlockType.exam:
        case BlockType.quiz:
          quizIndex++;
          entries.add(LectureTocEntry(
            label: block.metadata?['title']?.toString() ?? 'اختبار قصير $quizIndex',
            icon: Icons.help_outline,
          ));
      }
    }
    if (_exams.isNotEmpty) {
      entries.add(const LectureTocEntry(
        label: 'الامتحانات الختامية',
        icon: Icons.emoji_events_outlined,
      ));
    }
    return entries;
  }

  int _parseDurationSeconds(String raw) {
    if (raw.isEmpty) return 0;
    final parts = raw.split(':').map((p) => int.tryParse(p.trim())).toList();
    if (parts.isEmpty || parts.any((p) => p == null)) return 0;
    int seconds = 0;
    for (final p in parts) {
      seconds = seconds * 60 + p!;
    }
    return seconds;
  }

  String get _durationLabel {
    int seconds = 0;
    for (final block in _lecture!.contentBlocks) {
      if (block.type == BlockType.youtube) {
        seconds += _parseDurationSeconds(block.metadata?['duration']?.toString() ?? '');
      } else if (block.type == BlockType.text) {
        seconds += block.content.length ~/ 3;
      }
    }
    if (seconds == 0) return 'غير محدد';
    final minutes = (seconds / 60).ceil();
    return '$minutes دقيقة تقريباً';
  }

  int get _questionCount => _exams.fold(0, (sum, e) => sum + e.questions.length);

  List<ProgressSegmentData> _progressSegments(Color categoryColor) {
    int textTotal = 0, textDone = 0;
    int videoTotal = 0, videoDone = 0;
    int quizTotal = 0, quizDone = 0;
    for (final block in _lecture!.contentBlocks) {
      final done = _completedBlockIds.contains(block.id);
      switch (block.type) {
        case BlockType.text:
          textTotal++;
          if (done) textDone++;
        case BlockType.youtube:
          videoTotal++;
          if (done) videoDone++;
        case BlockType.exam:
        case BlockType.quiz:
          quizTotal++;
          if (done) quizDone++;
      }
    }
    final examTotal = _exams.length;
    final examDone = _exams.where((e) => _examScores.containsKey(e.id)).length;
    return [
      if (textTotal > 0)
        ProgressSegmentData(
          label: 'قراءة',
          icon: Icons.notes,
          total: textTotal,
          completed: textDone,
          color: categoryColor,
        ),
      if (videoTotal > 0)
        ProgressSegmentData(
          label: 'فيديو',
          icon: Icons.play_circle_outline,
          total: videoTotal,
          completed: videoDone,
          color: AppColors.accent,
        ),
      if (quizTotal > 0)
        ProgressSegmentData(
          label: 'اختبارات قصيرة',
          icon: Icons.help_outline,
          total: quizTotal,
          completed: quizDone,
          color: AppColors.examWarning,
        ),
      if (examTotal > 0)
        ProgressSegmentData(
          label: 'امتحانات',
          icon: Icons.emoji_events_outlined,
          total: examTotal,
          completed: examDone,
          color: AppColors.examPass,
        ),
    ];
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
          controller: _scrollController,
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LectureHeroCard(
                title: _lecture!.title,
                description: _lecture!.description,
                categoryColor: categoryColor,
                questionCount: _questionCount,
                durationLabel: _durationLabel,
                onMarkAllRead: _markAllRead,
                onResetProgress: _resetProgress,
              ),
              const SizedBox(height: AppTokens.spacing16),
              ProgressBarCard(
                segments: _progressSegments(categoryColor),
                categoryColor: categoryColor,
              ),
              const SizedBox(height: AppTokens.spacing16),
              LectureToc(
                entries: _tocEntries,
                activeIndex: _activeTocIndex,
                categoryColor: categoryColor,
                onEntryTap: _jumpToEntry,
              ),
              ..._lecture!.contentBlocks.map(
                (block) => KeyedSubtree(
                  key: _blockKeys.putIfAbsent(block.id, () => GlobalKey()),
                  child: _buildContentBlock(block, categoryColor),
                ),
              ),
              if (_exams.isNotEmpty)
                KeyedSubtree(
                  key: _examsSectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                  ),
                ),
              const SizedBox(height: AppTokens.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
