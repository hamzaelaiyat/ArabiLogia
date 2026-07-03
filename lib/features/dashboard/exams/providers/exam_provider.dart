import 'package:flutter/material.dart';

class ExamProvider extends ChangeNotifier {
  bool _isExamInProgress = false;

  bool get isExamInProgress => _isExamInProgress;

  void startExam() {
    _isExamInProgress = true;
    notifyListeners();
  }

  void endExam() {
    _isExamInProgress = false;
    notifyListeners();
  }
}
