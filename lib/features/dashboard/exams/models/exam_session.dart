class ExamSession {
  final String examId;
  final String examTitle;
  final int durationMinutes;
  final int startTimestamp; // Unix milliseconds when exam started
  final Map<int, String?> selectedAnswers;

  const ExamSession({
    required this.examId,
    required this.examTitle,
    required this.durationMinutes,
    required this.startTimestamp,
    required this.selectedAnswers,
  });

  /// Calculate remaining seconds when app was backgrounded
  int getRemainingSeconds() {
    final totalDurationMs = durationMinutes * 60 * 1000;
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTimestamp;
    final remaining = totalDurationMs - elapsed;
    return (remaining / 1000).round();
  }

  /// Check if exam has expired
  bool get isExpired => getRemainingSeconds() <= 0;

  /// Get total duration in seconds
  int get totalDurationSeconds => durationMinutes * 60;

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'examTitle': examTitle,
      'durationMinutes': durationMinutes,
      'startTimestamp': startTimestamp,
      'selectedAnswers': selectedAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    final answersJson = json['selectedAnswers'] as Map<String, dynamic>;
    return ExamSession(
      examId: json['examId'] as String,
      examTitle: json['examTitle'] as String,
      durationMinutes: json['durationMinutes'] as int,
      startTimestamp: json['startTimestamp'] as int,
      selectedAnswers: answersJson.map(
        (key, value) => MapEntry(int.parse(key), value as String?),
      ),
    );
  }

  ExamSession copyWith({
    String? examId,
    String? examTitle,
    int? durationMinutes,
    int? startTimestamp,
    Map<int, String?>? selectedAnswers,
  }) {
    return ExamSession(
      examId: examId ?? this.examId,
      examTitle: examTitle ?? this.examTitle,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      selectedAnswers: selectedAnswers ?? Map.from(this.selectedAnswers),
    );
  }
}
