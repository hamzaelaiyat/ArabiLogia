import 'dart:convert';

class ExamSessionData {
  final String examId;
  final String examTitle;
  final int durationMinutes;
  final int startTimestamp;
  final Map<int, String?> selectedAnswers;
  final int expiresAt;

  ExamSessionData({
    required this.examId,
    required this.examTitle,
    required this.durationMinutes,
    required this.startTimestamp,
    required this.selectedAnswers,
    required this.expiresAt,
  });

  factory ExamSessionData.fromJson(Map<String, dynamic> json) {
    return ExamSessionData(
      examId: json['exam_id'] as String,
      examTitle: json['exam_title'] as String,
      durationMinutes: json['duration_minutes'] as int,
      startTimestamp: json['start_timestamp'] as int,
      selectedAnswers: (jsonDecode(json['selected_answers'] as String) as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as String?)),
      expiresAt: json['expires_at'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'exam_id': examId,
    'exam_title': examTitle,
    'duration_minutes': durationMinutes,
    'start_timestamp': startTimestamp,
    'selected_answers': jsonEncode(
      selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
    ),
    'expires_at': expiresAt,
  };
}
