import 'package:flutter/material.dart';

enum ExamLevel {
  level1(value: 1, passPercentage: 85, label: 'أسهل', color: Color(0xFF34C759)),
  level2(value: 2, passPercentage: 75, label: 'متوسط', color: Color(0xFFFFCC00)),
  level3(value: 3, passPercentage: 60, label: 'صعب', color: Color(0xFFFF3B30));

  const ExamLevel({
    required this.value,
    required this.passPercentage,
    required this.label,
    required this.color,
  });

  final int value;
  final int passPercentage;
  final String label;
  final Color color;

  static ExamLevel fromValue(int? value) {
    return ExamLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExamLevel.level1,
    );
  }
}
