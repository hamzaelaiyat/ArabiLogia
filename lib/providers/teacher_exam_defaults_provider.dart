import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TeacherExamDefaults {
  final String defaultTitle;
  final int defaultGrade;
  final int defaultDurationMinutes;
  final bool defaultDurationEnabled;
  final double defaultPoints;
  final bool defaultShuffleQuestions;
  final bool defaultShowCorrectAnswers;
  final bool defaultShowScore;

  const TeacherExamDefaults({
    this.defaultTitle = 'اختبار جديد',
    this.defaultGrade = 1,
    this.defaultDurationMinutes = 30,
    this.defaultDurationEnabled = false,
    this.defaultPoints = 1.0,
    this.defaultShuffleQuestions = false,
    this.defaultShowCorrectAnswers = true,
    this.defaultShowScore = true,
  });

  TeacherExamDefaults copyWith({
    String? defaultTitle,
    int? defaultGrade,
    int? defaultDurationMinutes,
    bool? defaultDurationEnabled,
    double? defaultPoints,
    bool? defaultShuffleQuestions,
    bool? defaultShowCorrectAnswers,
    bool? defaultShowScore,
  }) {
    return TeacherExamDefaults(
      defaultTitle: defaultTitle ?? this.defaultTitle,
      defaultGrade: defaultGrade ?? this.defaultGrade,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
      defaultDurationEnabled: defaultDurationEnabled ?? this.defaultDurationEnabled,
      defaultPoints: defaultPoints ?? this.defaultPoints,
      defaultShuffleQuestions: defaultShuffleQuestions ?? this.defaultShuffleQuestions,
      defaultShowCorrectAnswers: defaultShowCorrectAnswers ?? this.defaultShowCorrectAnswers,
      defaultShowScore: defaultShowScore ?? this.defaultShowScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'defaultTitle': defaultTitle,
    'defaultGrade': defaultGrade,
    'defaultDurationMinutes': defaultDurationMinutes,
    'defaultDurationEnabled': defaultDurationEnabled,
    'defaultPoints': defaultPoints,
    'defaultShuffleQuestions': defaultShuffleQuestions,
    'defaultShowCorrectAnswers': defaultShowCorrectAnswers,
    'defaultShowScore': defaultShowScore,
  };

  factory TeacherExamDefaults.fromJson(Map<String, dynamic> json) {
    return TeacherExamDefaults(
      defaultTitle: json['defaultTitle'] ?? 'اختبار جديد',
      defaultGrade: json['defaultGrade'] ?? 1,
      defaultDurationMinutes: json['defaultDurationMinutes'] ?? 30,
      defaultDurationEnabled: json['defaultDurationEnabled'] ?? false,
      defaultPoints: (json['defaultPoints'] ?? 1.0).toDouble(),
      defaultShuffleQuestions: json['defaultShuffleQuestions'] ?? false,
      defaultShowCorrectAnswers: json['defaultShowCorrectAnswers'] ?? true,
      defaultShowScore: json['defaultShowScore'] ?? true,
    );
  }
}

class TeacherExamDefaultsProvider extends ChangeNotifier {
  static const String _storageKey = 'teacher_exam_defaults';
  TeacherExamDefaults _defaults = const TeacherExamDefaults();
  bool _isLoaded = false;

  TeacherExamDefaults get defaults => _defaults;
  bool get isLoaded => _isLoaded;

  TeacherExamDefaultsProvider() {
    // Lazy initialization - loadDefaults() will be called explicitly after app starts
  }

  Future<void> loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _defaults = TeacherExamDefaults.fromJson(json);
      } catch (e) {
        _defaults = const TeacherExamDefaults();
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_defaults.toJson());
    await prefs.setString(_storageKey, jsonStr);
  }

  Future<void> setDefaultTitle(String value) async {
    _defaults = _defaults.copyWith(defaultTitle: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> setDefaultGrade(int value) async {
    _defaults = _defaults.copyWith(defaultGrade: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> setDefaultDurationMinutes(int value) async {
    _defaults = _defaults.copyWith(defaultDurationMinutes: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> setDefaultDurationEnabled(bool value) async {
    _defaults = _defaults.copyWith(defaultDurationEnabled: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> setDefaultPoints(double value) async {
    _defaults = _defaults.copyWith(defaultPoints: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> setDefaultShuffleQuestions(bool value) async {
    _defaults = _defaults.copyWith(defaultShuffleQuestions: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> setDefaultShowCorrectAnswers(bool value) async {
    _defaults = _defaults.copyWith(defaultShowCorrectAnswers: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> setDefaultShowScore(bool value) async {
    _defaults = _defaults.copyWith(defaultShowScore: value);
    await _saveDefaults();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _defaults = const TeacherExamDefaults();
    await _saveDefaults();
    notifyListeners();
  }
}