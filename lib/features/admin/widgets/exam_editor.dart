import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/dashboard/exams/models/exam_model.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_state.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_preview_overlay.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_exit_confirmation.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_desktop_layout.dart';
import 'package:arabilogia/features/admin/widgets/exam_editor_mobile_layout.dart';
import 'package:arabilogia/providers/teacher_exam_defaults_provider.dart';

class ExamEditor extends StatelessWidget {
  final Exam? existingExam;
  final Function(Exam) onSave;
  final VoidCallback onCancel;
  final TeacherExamDefaults? defaults;

  const ExamEditor({
    super.key,
    this.existingExam,
    required this.onSave,
    required this.onCancel,
    this.defaults,
  });

  @override
  Widget build(BuildContext context) {
    final examDefaults = defaults ?? context.read<TeacherExamDefaultsProvider?>()?.defaults;
    return ChangeNotifierProvider(
      create: (_) {
        if (existingExam != null) {
          return ExamEditorState.fromExam(existingExam!);
        } else {
          return ExamEditorState.empty(defaults: examDefaults);
        }
      },
      child: _ExamEditorContent(
        onSave: onSave,
        onCancel: onCancel,
      ),
    );
  }
}

class _ExamEditorContent extends StatefulWidget {
  final Function(Exam) onSave;
  final VoidCallback onCancel;

  const _ExamEditorContent({
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ExamEditorContent> createState() => _ExamEditorContentState();
}

class _ExamEditorContentState extends State<_ExamEditorContent> with TickerProviderStateMixin {
  final PageController _questionPageController = PageController();
  late TabController _tabController;
  bool _isPreviewOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _questionPageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _saveExam({bool publish = false}) {
    final state = context.read<ExamEditorState>();
    final validation = state.validate();
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.errorMessage!)),
      );
      return;
    }
    widget.onSave(state.toExam(publish: publish));
  }

  void _addPassage(String title, String content, [String imageUrl = '']) {
    context.read<ExamEditorState>().addPassage(title, content, imageUrl);
  }

  void _deletePassage(int index) {
    context.read<ExamEditorState>().deletePassage(index);
  }

  void _togglePreview() {
    setState(() {
      _isPreviewOpen = !_isPreviewOpen;
    });
    context.read<ExamEditorState>().setShowPreview(_isPreviewOpen);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppTokens.breakpointTablet;

        final content = isDesktop
            ? ExamEditorDesktopLayout(
                isDark: isDark,
                onSaveDraft: () => _saveExam(publish: false),
                onPublish: () => _saveExam(publish: true),
                onExit: () => ExamEditorExitConfirmation.show(
                  context: context,
                  onCancel: widget.onCancel,
                  onSaveDraft: () => _saveExam(publish: false),
                ),
                onCancel: widget.onCancel,
                onAddPassage: _addPassage,
                onDeletePassage: _deletePassage,
              )
            : ExamEditorMobileLayout(
                onSaveDraft: () => _saveExam(publish: false),
                onPublish: () => _saveExam(publish: true),
                onExit: () => ExamEditorExitConfirmation.show(
                  context: context,
                  onCancel: widget.onCancel,
                  onSaveDraft: () => _saveExam(publish: false),
                ),
                onCancel: widget.onCancel,
                onAddPassage: _addPassage,
                onDeletePassage: _deletePassage,
              );

        return Consumer<ExamEditorState>(
          builder: (context, state, _) {
            return Stack(
              children: [
                content,
                ExamPreviewOverlay(
                  isVisible: state.showPreview,
                  isDesktop: isDesktop,
                  questions: state.questions,
                  questionSettings: state.questionSettings,
                  onClose: _togglePreview,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
