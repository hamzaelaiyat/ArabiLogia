import 'package:flutter/material.dart';
import 'package:arabilogia/features/dashboard/lectures/widgets/lecture_toc.dart';

class LectureSidebarData {
  final String lectureId;
  final String title;
  final String categoryName;
  final Color categoryColor;
  final List<LectureTocEntry> tocEntries;
  final int activeIndex;
  final ValueChanged<int> onEntryTap;
  final VoidCallback onBack;
  final VoidCallback? onShowMainSidebar;

  const LectureSidebarData({
    required this.lectureId,
    required this.title,
    required this.categoryName,
    required this.categoryColor,
    required this.tocEntries,
    required this.activeIndex,
    required this.onEntryTap,
    required this.onBack,
    this.onShowMainSidebar,
  });
}

class ExamSidebarData {
  final String examId;
  final String title;
  final String categoryName;
  final Color categoryColor;
  final int questionCount;
  final int currentIndex;
  final Map<int, String?> selectedAnswers;
  final Map<int, bool> flaggedQuestions;
  final ValueNotifier<int>? timerNotifier;
  final ValueChanged<int> onSelectQuestion;
  final ValueChanged<int> onToggleFlag;
  final VoidCallback onExitExam;

  const ExamSidebarData({
    required this.examId,
    required this.title,
    required this.categoryName,
    required this.categoryColor,
    required this.questionCount,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.flaggedQuestions,
    this.timerNotifier,
    required this.onSelectQuestion,
    required this.onToggleFlag,
    required this.onExitExam,
  });
}

enum SidebarMode { defaultNav, lectureToc, examNavigation }

class ContextualSidebarProvider extends ChangeNotifier {
  SidebarMode _mode = SidebarMode.defaultNav;
  LectureSidebarData? _lectureData;
  ExamSidebarData? _examData;
  bool _isTocTemporarilyHidden = false;
  bool _forceHideBottomNav = false;

  SidebarMode get mode => _mode;
  LectureSidebarData? get lectureData => _lectureData;
  ExamSidebarData? get examData => _examData;
  bool get isTocTemporarilyHidden => _isTocTemporarilyHidden;
  bool get shouldHideBottomNav => _forceHideBottomNav || _mode == SidebarMode.examNavigation;

  void setHideBottomNav(bool hide) {
    _forceHideBottomNav = hide;
    notifyListeners();
  }

  void showMainSidebar() {
    _isTocTemporarilyHidden = true;
    notifyListeners();
  }

  void showTocSidebar() {
    _isTocTemporarilyHidden = false;
    notifyListeners();
  }

  void setLectureSidebar(LectureSidebarData data) {
    _mode = SidebarMode.lectureToc;
    _lectureData = data;
    _examData = null;
    _isTocTemporarilyHidden = false;
    notifyListeners();
  }

  void updateLectureActiveIndex(int index) {
    if (_lectureData != null && _lectureData!.activeIndex != index) {
      _lectureData = LectureSidebarData(
        lectureId: _lectureData!.lectureId,
        title: _lectureData!.title,
        categoryName: _lectureData!.categoryName,
        categoryColor: _lectureData!.categoryColor,
        tocEntries: _lectureData!.tocEntries,
        activeIndex: index,
        onEntryTap: _lectureData!.onEntryTap,
        onBack: _lectureData!.onBack,
        onShowMainSidebar: _lectureData!.onShowMainSidebar,
      );
      notifyListeners();
    }
  }

  void setExamSidebar(ExamSidebarData data) {
    _mode = SidebarMode.examNavigation;
    _examData = data;
    _lectureData = null;
    notifyListeners();
  }

  void updateExamSidebarState({
    int? currentIndex,
    Map<int, String?>? selectedAnswers,
    Map<int, bool>? flaggedQuestions,
  }) {
    if (_examData != null) {
      _examData = ExamSidebarData(
        examId: _examData!.examId,
        title: _examData!.title,
        categoryName: _examData!.categoryName,
        categoryColor: _examData!.categoryColor,
        questionCount: _examData!.questionCount,
        currentIndex: currentIndex ?? _examData!.currentIndex,
        selectedAnswers: Map.from(selectedAnswers ?? _examData!.selectedAnswers),
        flaggedQuestions: Map.from(flaggedQuestions ?? _examData!.flaggedQuestions),
        timerNotifier: _examData!.timerNotifier,
        onSelectQuestion: _examData!.onSelectQuestion,
        onToggleFlag: _examData!.onToggleFlag,
        onExitExam: _examData!.onExitExam,
      );
      notifyListeners();
    }
  }

  void clearSidebar() {
    _mode = SidebarMode.defaultNav;
    _lectureData = null;
    _examData = null;
    notifyListeners();
  }
}
